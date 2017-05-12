package Queue::Q::ReliableFIFO::Lua;
use Redis;
use File::Slurp;
use Digest::SHA1;
use Carp qw(croak);
use Class::XSAccessor {
    getters => [qw(redis_conn script_dir)]
};
my %Scripts;

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;
    $self->redis_conn || croak("need a redis connection");
    $self->{script_dir} ||= $ENV{LUA_SCRIPT_DIR};
    $self->{call} ||= {};
    $self->register;
    return $self;
}

sub register {
    my $self = shift;
    my $name = shift;
    if ($self->script_dir) {
        $name ||= '*';
        for my $file (glob("$self->{script_dir}/$name.lua")) {
            my $script = read_file($file);
            my $sha1 = Digest::SHA1::sha1_hex($script);
            my ($found) = @{$self->redis_conn->script_exists($sha1)};
            if (!$found) {
                print "registering $file\n";
                my $rv = $self->redis_conn->script_load($script);
                croak("returned sha1 is different from ours!")
                    if ($rv ne $sha1);
            }
            (my $call = $file) =~ s/\.lua$//;
            $call =~ s/^.*\///;
            $self->{call}{$call} = $sha1;
        }
    }
    else {
        croak("script $name not found") if $name && !exists $Scripts{$name};
        my @names = $name ? ($name) : (keys %script);
        for my $scr_name (@names) {
            my $script = $Scripts{$scr_name};
            my $sha1 = Digest::SHA1::sha1_hex($script);
            my ($found) = @{$self->redis_conn->script_exists($sha1)};
            if (!$found) {
                my $rv = $self->redis_conn->script_load($script);
                croak("returned sha1 is different from ours!") 
                    if ($rv ne $sha1);
            }
            $self->{call}{$scr_name} = $sha1;
        }
    }
}
sub call {
    my $self = shift;
    my $name = shift;
    $self->register($name) if not exists $self->{call}{$name};
    my $sha1 = $self->{call}{$name};
    croak("Unknown script $name") if ! $sha1;
    return $self->redis_conn->evalsha($sha1, @_);
}

##################################
# Start of Lua script section
%Scripts = (
remove_failed_gentle => q{
-- remove_failed_gentle: requeue or requeue up to a given number of items
--   first call will rename the list to a temporary list
--   calls after that will work through the temporary list until is empty
-- # KEYS[1] from queue name (failed queue)
-- # KEYS[2] temp queue name (temporary queue)
-- # KEYS[3] log queue name (temporary queue)
-- # ARGV[1] timestamp
-- # ARGV[2] number of items to requeue. Value "0" means "all items"
-- # ARGV[3] lowest creation timestamp to alloow for the failed queue
-- # ARGV[4] failed counter criterium
-- # ARGV[5] max amount of log entries
--
if #KEYS ~= 3 then error('remove_failed_gentle.lua requires 3 keys') end
-- redis.log(redis.LOG_NOTICE, "nr keys: " .. #KEYS)
local from  = assert(KEYS[1], 'failed queue name missing')
local temp  = assert(KEYS[2], 'temp queue name missing')
local log   = assert(KEYS[3], 'log queue name missing')
local ts    = assert(tonumber(ARGV[1]), 'timestamp missing')
local num   = assert(tonumber(ARGV[2]), 'number of items missing')
local tmin  = assert(tonumber(ARGV[3]), 'tmin criterium missing')
local fc    = assert(tonumber(ARGV[4]), 'failed counter criterium missing')
local loglimit = assert(tonumber(ARGV[5]), 'log limit missing')
local todo     = 0
local n_removed = 0
local do_log = 1

if redis.call('exists', temp) == 0 then
    if redis.call('exists', from) == 1 then
        redis.call('rename', from, temp)
    else
        return "0 0"
    end
end

local len = redis.call('llen', temp)

if len > 0 then
    if num == 0 or num > len then
        num = len
    end

    -- we don't want millions of log items.
    if redis.call('llen', log) >= loglimit then
        do_log = 0
    end

    for i = 1, num do
        local item = redis.call('rpop', temp)
        if not item then break end

        local i = cjson.decode(item)

        if i.fc >= fc or i.t < tmin or (i.created ~= nil and i.created < tmin) then
            -- item should be removed
            n_removed = n_removed + 1
            if do_log then
                -- permanent fail, put it in a log queue
                redis.call('lpush', log, item)
            end
        else
            -- it's not yet a permanent fail
            redis.call('lpush', from, item)
        end
    end
end

-- throw away exceeding log entries
if do_log then
    redis.call('ltrim',log,0,loglimit-1)
end

-- return number of items handled and number of items removed from the failed
-- queue, space separated (as a string)
todo = len - num
return todo .. ' ' .. n_removed
},
requeue_busy => q{
-- requeue_busy (depending requeue limit items will be requeued or fail)
-- # KEYS[1] from queue name (busy queue)
-- # KEYS[2] dest queue name (main queue)
-- # KEYS[3] failed queue name (failed queue)
-- # ARGV[1] timestamp
-- # ARGV[2] item
-- # ARGV[3] requeue limit
-- # ARGV[4] place to requeue in dest-queue:
--      0: at producer side, 1: consumer side
--      Note: failed items will always go to the tail of the failed queue
-- # ARGV[5] OPTIONAL error message
--
--redis.log(redis.LOG_WARNING, "requeue_tail")
if #KEYS ~= 3 then error('requeue_busy requires 3 keys') end
-- redis.log(redis.LOG_NOTICE, "nr keys: " .. #KEYS)
local from  = assert(KEYS[1], 'busy queue name missing')
local dest  = assert(KEYS[2], 'dest queue name missing')
local failed= assert(KEYS[3], 'failed queue name missing')
local ts    = assert(tonumber(ARGV[1]), 'timestamp missing')
local item  = assert(ARGV[2], 'item missing')
local limit = assert(tonumber(ARGV[3]), 'requeue limit missing')
local place = tonumber(ARGV[4])
assert(place == 0 or place == 1, 'requeue place should be 0 or 1')

local n = redis.call('lrem', from, 1, item)

if n > 0 then
    local i= cjson.decode(item)
    if i.rc == nil then
        i.rc=1
    else
        i.rc=i.rc+1
    end

    if i.rc <= limit then
        -- only adjust timestamps in case of requeuing
        -- (not if busy item is place back in the front of the queue)
        if place == 0 then
            if i.t_created == nil then
                i.t_created = i.t
            end
            i.t = ts
        end

        local v=cjson.encode(i)
        if place == 0 then 
            redis.call('lpush', dest, v)
        else
            redis.call('rpush', dest, v)
        end
    else
        -- reset requeue counter and increase fail counter
        i.rc = nil
        if i.fc == nil then
            i.fc = 1
        else
            i.fc = i.fc + 1
        end
        if #ARGV == 5 then
            i.error = ARGV[5]
        else
            i.error = nil
        end
        local v=cjson.encode(i)
        redis.call('lpush', failed, v)
    end
end
return n
},
requeue_failed => q{
-- requeue_failed: requeue a given number of failed items
-- # KEYS[1] from queue name (failed queue)
-- # KEYS[2] dest queue name (main queue)
-- # ARGV[1] timestamp
-- # ARGV[2] number of items to requeue. Value "0" means "all items"
--
if #KEYS ~= 2 then error('requeue_failed requires 2 keys') end
-- redis.log(redis.LOG_NOTICE, "nr keys: " .. #KEYS)
local from  = assert(KEYS[1], 'failed queue name missing')
local dest  = assert(KEYS[2], 'dest queue name missing')
local ts    = assert(tonumber(ARGV[1]), 'timestamp missing')
local num   = assert(tonumber(ARGV[2]), 'number of items missing')
local n     = 0;

if num == 0 then
    num = redis.call('llen', from)
end

for i = 1, num do
    local item = redis.call('rpop', from);
    if item == nil then break end

    local i = cjson.decode(item)

    if i.t_created == nil then
        i.t_created = i.t
    end
    i.t = ts

    local v = cjson.encode(i)
    redis.call('lpush', dest, v)

    n = n + 1
end
return n
},
requeue_failed_gentle => q{
-- requeue_failed_gentle: requeue or requeue up to a given number of items
--   first call will rename the list to a temporary list
--   calls after that will work through the temporary list until is empty
-- # KEYS[1] from queue name (failed queue)
-- # KEYS[2] dest queue name (main queue)
-- # KEYS[3] temp queue name (temporary queue)
-- # ARGV[1] timestamp
-- # ARGV[2] number of items to requeue. Value "0" means "all items"
-- # ARGV[3] delay before trying again after a fail
-- # ARGV[4] failed counter criterium
--
if #KEYS ~= 3 then error('requeue_failed_gentle.lua requires 3 keys') end
-- redis.log(redis.LOG_NOTICE, "nr keys: " .. #KEYS)
local from  = assert(KEYS[1], 'failed queue name missing')
local dest  = assert(KEYS[2], 'dest queue name missing')
local temp  = assert(KEYS[3], 'temp queue name missing')
local ts    = assert(tonumber(ARGV[1]), 'timestamp missing')
local num   = assert(tonumber(ARGV[2]), 'number of items missing')
local delay = assert(tonumber(ARGV[3]), 'delay criterium missing')
local fc    = assert(tonumber(ARGV[4]), 'failed counter criterium missing')
local n_requeued = 0
local tmin  = 0

if redis.call('exists', temp) == 0 then
    if redis.call('exists', from) == 1 then
        redis.call('rename', from, temp)
    else
        return "0 0"
    end
end

local len = redis.call('llen', temp)

if len > 0 then
    if num == 0 or num > len then
        num = len
    end

    for i = 1, num do
        local item = redis.call('rpop', temp);
        if not item then break end

        local i = cjson.decode(item)
        tmin = ts - i.fc*delay

        if (fc == -1 or i.fc <= fc) and 
            (i.t <= tmin or (i.created ~= nil and i.created <=tmin)) then

            -- item should be requeued
            n_requeued = n_requeued + 1
            if i.t_created == nil then
                i.t_created = i.t
            end
            i.t = ts

            local v = cjson.encode(i)
            redis.call('lpush', dest, v)
        else
            -- put it back in failed queue
            redis.call('lpush', from, item)
        end
    end
end

-- return number of items handled and number of items removed from the failed
-- queue, space separated (as a string)
local todo = len - num
return todo .. ' ' .. n_requeued
},
requeue_failed_item => q{
-- Requeue_busy_items
-- # KEYS[1] from queue name (failed queue)
-- # KEYS[2] dest queue name (main queue)
-- # ARGV[1] timestamp
-- # ARGV[2] item
--
-- redis.log(redis.LOG_WARNING, "requeue_tail")
if #KEYS ~= 2 then error('requeue_failed_item requires 2 keys') end
-- redis.log(redis.LOG_NOTICE, "nr keys: " .. #KEYS)
local from  = assert(KEYS[1], 'failed queue name missing')
local dest  = assert(KEYS[2], 'dest queue name missing')
local ts    = assert(tonumber(ARGV[1]), 'timestamp missing')
local item  = assert(ARGV[2], 'item missing')

local n = redis.call('lrem', from, 1, item)

if n > 0 then
    local i = cjson.decode(item)

    if i.t_created == nil then
        i.t_created = i.t
    end
    i.t = ts

    local v = cjson.encode(i)
    redis.call('lpush', dest, v)
end
return n
});

1;

__END__

=head1 NAME

Queue::Q::ReliableFIFO::Lua - Load lua scripts into Redis

=head1 SYNOPSIS

  use Queue::Q::ReliableFIFO::Lua;
  my $lua = Queue::Q::ReliableFIFO::Lua->new(
    script_dir => /some/path
    redis_conn => $redis_conn);

  $lua->call('myscript', $n, @keys, @argv);

=head1 DESCRIPTION

This module offers two ways of loading/running Lua scripts.

One way
is with separate Lua scripts, which live at a location as indicated
by the C<script_dir> parameter (passed to the constructor) or as 
indicated by the C<LUA_SCRIPT_DIR> environment variable.

The other way is by putting the source code of the Lua scripts in
this module, in the C<%Scripts> hash.

Which way is actually used depends on whether or not passing info
about a path to Lua scripts. If a Lua script location is known, those
script will be used, otherwise the C<%Scripts> code is used.

During development it is more convenient to use the separate Lua files
of course. But for deploying it is less error prone if the Lua code
is inside the Perl module. So that is why this is done this way.

The scripts are loaded when the constructor is called.

