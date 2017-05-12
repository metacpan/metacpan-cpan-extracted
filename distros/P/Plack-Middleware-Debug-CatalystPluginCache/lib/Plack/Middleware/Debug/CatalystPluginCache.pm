package Plack::Middleware::Debug::CatalystPluginCache;
BEGIN {
  $Plack::Middleware::Debug::CatalystPluginCache::VERSION = '0.101';
}

use 5.008;
use strict;
use warnings;

use Plack::Util::Accessor qw(app_class track_miss_locations show_process_stats show_global_stats);
use Class::Method::Modifiers qw(install_modifier);
use Text::MicroTemplate qw(encoded_string);

use parent qw(Plack::Middleware::Debug::Base);

my @stat_keys = qw(cache_get_hit cache_get_miss cache_set cache_remove cache_compute);
my $track_miss_locations; # fudge, to be visible to method hooks
my $process_stats_req_count = 0;
my %process_stats;  # process stats keyed by cache name
my %be_stat;        # request stats keyed by backend ref


sub _install_method_hooks {

    install_modifier 'Catalyst::Plugin::Cache', 'before', 'cache_set' => sub {
        my ( $c, $key, $value, @meta ) = @_;
        my $backend = $c->choose_cache_backend_wrapper(key => $key, value => $value, @meta);
        $be_stat{$backend}->{cache_set}++;
    };

    install_modifier 'Catalyst::Plugin::Cache', 'before', 'cache_remove' => sub {
        my ( $c, $key, @meta ) = @_;
        my $backend = $c->choose_cache_backend_wrapper( key => $key, @meta );
        $be_stat{$backend}->{cache_remove}++;
    };

    # XXX if a backend supports compute then we can't tell what happened,
    # if not, then either cache_get_hit or cache_get_miss+cache_set will also
    # be incremented. We could force explicit get+set calls.
    install_modifier 'Catalyst::Plugin::Cache', 'before', 'cache_compute' => sub {
        my ($c, $key, $code, @meta) = @_;
        my $backend = $c->choose_cache_backend_wrapper( key => $key, @meta );
        $be_stat{$backend}->{cache_compute}++;
    };

    install_modifier 'Catalyst::Plugin::Cache', 'around', 'cache_get' => sub {
        my $orig = shift;
        my $c = shift;
        my $backend = $c->choose_cache_backend_wrapper( key => @_ );
        if (defined(my $result = $c->$orig(@_))) { # XXX we assume scalar context
            $be_stat{$backend}->{cache_get_hit}++;
            return $result;
        }
        $be_stat{$backend}->{cache_get_miss}++;

        if ($track_miss_locations) {
            my $p = $be_stat{$backend}->{cache_get_miss_call_tree} ||= {};
            my $level = 2;
            while (my ($pkg, $file, $line, $sub) = caller(++$level)) {
                next if $pkg =~ /^(?:Class::MOP|Plack|Class::Method|Try::Tiny)\b/;
                $p = $p->{"$pkg\::$sub\@$line"} ||= {};
            }
            $p->{misses}++;
        }

        return undef;
    };
}


sub prepare_app {
    my $self = shift;

    if (not $self->app_class) {

        my $apps = mro::get_isarev('Catalyst');
        die "There doesn't seem to be a Catalyst application class\n"
            unless @$apps;

        die "The CatalystPluginCache needs an app_class config option specified (one of @$apps)\n"
            if @$apps > 1;

        $self->app_class($apps->[0]);
    }

    if ($INC{'Catalyst/Plugin/Cache.pm'}) {
        _install_method_hooks() if $INC{'Catalyst/Plugin/Cache.pm'};
    }
    else {
        warn __PACKAGE__." will be inefective because Catalyst::Plugin::Cache is not loaded\n";
    }

    $self->show_process_stats(1) if not defined $self->show_process_stats;

    $track_miss_locations = $self->track_miss_locations;
}


sub run {
    my($self, $env, $panel) = @_;

    %be_stat = ();

    $self->_store_current_cache_global_stats('global_stats_pre')
        if $self->show_global_stats;

    return sub {
        my $res = shift;
        ++$process_stats_req_count;

        $self->_store_current_cache_global_stats('global_stats_post')
            if $self->show_global_stats;

        my $cbe = $self->app_class->_cache_backends;
        # include configured but unused caches
        $be_stat{$_} ||= {} for values %$cbe;

        my %cache_be2name = reverse %$cbe;
        my %cache_stat_by_name = map {
            ($cache_be2name{$_} || $_) => $be_stat{$_} ||= {}
        } values %$cbe;

        # add per-cache hit_ratio and calc total gets and hits
        my ($t_gets, $t_hits) = (0, 0);
        while ( my ($cache_name, $stats) = each %cache_stat_by_name) {
            $stats->{$_} ||= 0 for @stat_keys; # avoid undefs

            $stats->{cache_gets} = $stats->{cache_get_hit} + $stats->{cache_get_miss};
            $t_gets += $stats->{cache_gets};
            $t_hits += $stats->{cache_get_hit};

            my $process_stats = $process_stats{$cache_name} ||= {};
            $process_stats->{$_} += $stats->{$_} for (@stat_keys, 'cache_gets');
        }

        $panel->nav_subtitle( sprintf "%.1f%% of %d hit", $t_hits/$t_gets*100, $t_gets )
            if $t_gets;

        my $cache_stat_content = sub {
            my ($cache_stats, %opts) = @_;
            my $headings = ['Cache', 'Get', 'Miss', 'Hit%', 'Set', 'Compute', 'Remove', 'Backend'];
            my @rows;
            for my $name (sort keys %$cache_stats) {
                my $stats = $cache_stats->{$name};
                my $gets = $stats->{cache_gets};
                $stats->{hit_pct} = ($gets) ? sprintf "%.2f", $stats->{cache_get_hit}/$gets*100 : 0;
                push @rows, [
                    $name, @{$stats}{qw(cache_gets cache_get_miss hit_pct cache_set cache_compute cache_remove)}, $cbe->{$name}
                ];
            }
            return $self->render_table(
                caption => $opts{caption} || "Cache stats for this request:",
                headings => $headings,
                list => \@rows
            );
        };
        $panel->content( $cache_stat_content->(\%cache_stat_by_name) );

        $self->_add_content($panel, 'track_miss_locations', sub {
            my $html = '';
            for my $name (sort keys %cache_stat_by_name) {
                my $tree = $cache_stat_by_name{$name}{cache_get_miss_call_tree}
                    or next;
                my $dump = Data::Dumper->new([$tree])->Indent(1)->Terse(1)->Sortkeys(1)->Dump;
                $dump = _tidy_dump($dump);
                $dump =~ s/  /. /g;           # add dots to aid visual alignment
                my $miss_call_tree = Text::MicroTemplate::escape_html($dump);
                $miss_call_tree = encoded_string("<pre>$miss_call_tree</pre>");

                my $headings = ["Call paths for misses in the $name cache:"];
                my @rows = ([ $miss_call_tree ]);
                $html .= $self->render_table(headings => $headings, list => \@rows);
            }
            return $html;
        });

        $self->_add_content($panel, 'show_global_stats', sub {
            my @rows;
            for my $name (sort keys %cache_stat_by_name) {
                my $pre  = $cache_stat_by_name{$name}{global_stats_pre} or next;
                my $post = $cache_stat_by_name{$name}{global_stats_post} or next;
                my @diff;
                for my $key (sort keys %$post) {
                    next if $pre->{$key} eq $post->{$key};
                    push @diff, sprintf "%s: %+d", $key, $post->{$key} - $pre->{$key};
                }
                push @rows, [ $name, join ", ", @diff ];
            }
            return "" unless @rows;
            return $self->render_table(
                caption => "Global backend cache server stats (may be affected by other clients using the cache services)",
                headings => ['Cache', 'Global stats changes during time of request'],
                list => \@rows
            );
        });

        $self->_add_content($panel, 'show_process_stats', sub {
            $cache_stat_content->(\%process_stats,
                caption => "Cache stats for the life of this process ($process_stats_req_count requests to pid $$)"
            );
        });

        $panel->content( $panel->content . "<br />" );
    };
}


sub _add_content {
    my ($self, $panel, $attrib, $sub) = @_;

    # if $attrib isn't enabled, replace $sub with a stub
    $sub = sub { $self->render_lines([ "$attrib not enabled in configuration" ]) }
        if not $self->$attrib;

    $panel->content( $panel->content . $sub->() );
}


sub _tidy_dump {
    my $dump = shift;
    $dump =~ s/^[{ ].$//mg;       # remove left-most indentation
    $dump =~ s/\s*{\s*$//mg;      # remove all trailing open braces
    $dump =~ s/^\s*\},?\s*\n//mg; # remove 'empty' closing brace lines
    $dump =~ s/'//g;              #remove quotes
    return $dump;
}


sub _store_current_cache_global_stats {
    my ($self, $key) = @_;

    my $app_class = $self->app_class;
    my $cbe = $app_class->_cache_backends;

    while ( my ($cbe_name, $cache) = each %$cbe ) {
        my $orig_stat;

        if ($cache->isa('Cache::Memcached::libmemcached')) {
            # XXX https://rt.cpan.org/Ticket/Display.html?id=62163
            local $SIG{__WARN__} = sub {
                warn @_ unless $_[0] =~ /Argument "" isn't numeric in addition/;
            };
            # XXX this could be made smarter to only query caches that have
            # different configurations (eg different sets of servers)
            $orig_stat = $cache->stats->{total};
        }
        else {
            warn sprintf "Cache %s is %s which isn't supported by %s",
                    $cbe_name, ref $cache, __PACKAGE__
                unless our $warn_unsupported->{ref $cache}++;
        }
        $be_stat{$cache}{$key} = $orig_stat;
    }
}


# --- this section should be in lib/Plack/Middleware/Debug/Base.pm ---

*vardump = \&Plack::Middleware::Debug::Base::vardump; # import
my $table_template = __PACKAGE__->build_template(<<'EOTMPL');
<table>
% if (my $caption = $_[0]->{caption}) {
    <caption><%= $caption %></caption>
% }
% if (my $headings = $_[0]->{headings}) {
  <thead>
    <tr>
%   for my $heading (@$headings) {
      <th><%= $heading %></th>
%   }
    </tr>
  </thead>
% }
  <tbody>
% my $i;
% while (my $row = shift @{$_[0]->{list}}) {
    <tr class="<%= ++$i % 2 ? 'plDebugOdd' : 'plDebugEven' %>">
%   for my $value (@$row) {
      <td><%= $value %></td>
%   }
    </tr>
% }
    </tbody>
</table>
EOTMPL

sub render_table {
    my ($self, %args) = @_;
    $self->render($table_template, \%args);
}


1;
__END__

=head1 NAME

Plack::Middleware::Debug::CatalystPluginCache - Panel for monitoring Catalyst::Plugin::Cache's

=head1 VERSION

version 0.101

=head1 SYNOPSIS

    enable "Debug:CatalystPluginCache";

is equivalent to:

    enable "Debug:CatalystPluginCache",
        app_class => '...', # Catalyst class name is determined automatically
        show_process_stats   => 1,
        show_global_stats    => 0,
        track_miss_locations => 0;

=head1 DESCRIPTION

=head2 General

The default output consists of a summary of cache statistics, for each of the
caches configured for L<Catalyst::Plugin::Cache>, for the current request:

    Cache   Get   Miss  Hit%  Set Compute Remove  Backend
    default 11    10    9.09  11  0       0       Cache::Memcached::libmemcached=HASH(0xa682020)

This becomes more useful as more L<Catalyst::Plugin::Cache> caches are
configured for different uses. You can then see more fine-grained details of
how effectively the different caches are being used.

=head2 track_miss_locations

If C<track_miss_locations> is enabled then, for each cache that had one or more
misses, a summary of the subroutine call paths that encountered the misses is
displayed:

    Call paths for misses in the default cache:
    . Catalyst::Plugin::PageCache::Catalyst::Plugin::Cache::Curried::get@106 =>
    . . Catalyst::Plugin::Static::Simple::Catalyst::Plugin::PageCache::dispatch@76 =>
    . . . Catalyst::Engine::PSGI::Hello::dispatch@158 =>
    . . . . Catalyst::Engine::PSGI::(eval)@156 =>
    . . . . . Catalyst::Catalyst::Engine::PSGI::run@2386 =>
    ...
    . . . . . . . misses => 1

Some 'uninteresting' packages are filtered out to aid readability.

=head2 show_process_stats

If C<show_process_stats> is enabled then a summary of the cache statistics is
shown, like L</General> above, except the stats refer to the lifetime of the
server process which handled the request. Typically only useful in development
environments with a single Plack application server process.

=head2 show_global_stats

If C<show_global_stats> is enabled then the cache backend service is queried
for global stats before and after the request is processed and the differences
in counts are displayed. For example:

    Cache    Global stats changes during time of request
    default  bytes: +2, bytes_read: +65915, bytes_written: +1635, cmd_get: +11, cmd_set: +11,
             curr_items: +1, evictions: +1, get_hits: +1, get_misses: +10, total_connections: +2, total_items: +11

Currently only global stats fromL<Cache::Memcached::libmemcached> based caches
are supported.  Others could be added easily.  Note that these backend cache
server stats will obviously be affected by any other clients using the cache
services. They are most useful in development environments with a dedicated
backend cache server.

=head1 SEE ALSO

L<Plack::Middleware::Debug>,
L<Cache::Memcached::libmemcached>

=cut