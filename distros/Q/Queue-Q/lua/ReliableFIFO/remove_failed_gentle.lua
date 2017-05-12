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
