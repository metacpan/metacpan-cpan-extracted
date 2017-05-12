package Plack::Middleware::Debug::DBIProfile;
BEGIN {
  $Plack::Middleware::Debug::DBIProfile::VERSION = '0.102';
}

use 5.008;
use strict;
use warnings;

use Plack::Util::Accessor qw(profile format);
use parent qw(Plack::Middleware::Debug::Base);

use DBI::Profile;
use Time::HiRes qw(gettimeofday);


sub prepare_app {
    my $self = shift;

    $self->profile(1)
        unless $self->profile;

    $self->format("Profile Path: %1\$s\nProfile Data: %11\$fs / %10\$d = %2\$fs avg (first %12\$fs, min %13\$fs, max %14\$fs)\n")
        unless $self->format;
}


sub run {
    my($self, $env, $panel) = @_;

    $panel->nav_title("DBI Profile");

    my $profile_obj = _set_profile_on_all_dbi_handles($self->profile);
    my $start_time = gettimeofday();

    return sub {
        my $res = shift;

        if ($profile_obj) {
            my $duration = gettimeofday() - $start_time;
            my $time_in_dbi = dbi_profile_merge_nodes(my $totals=[], $profile_obj->{Data});

            my $sep = "_" x 75;
            my @items = $profile_obj->as_text({
                format => $self->format."\n$sep\n",
                sortsub => sub {
                    my $ary = shift;
                    @$ary = sort { $b->[0][1] <=> $a->[0][1] } @$ary;
                },
            });
            $panel->content($self->render_lines(join "", @items));

            my $subtitle = sprintf "%.3f s (%d%%)",
                $time_in_dbi, ($duration) ? $time_in_dbi/$duration*100 : "-";
            # only show item count if >1 because they'll always be one
            # for profile==1, the default, so it's only noise, and for other
            # profile levels they'll always be an extra 'empty' item for
            # calls that can't be associated with a particular statement etc.
            $subtitle .= " #".@items if @items > 1;
            $panel->nav_subtitle($subtitle);

            # disable profiling and silently discard profile data
            local $DBI::Profile::ON_DESTROY_DUMP = sub { };
            _set_profile_on_all_dbi_handles(undef);
        }
    };
}


sub _set_profile_on_all_dbi_handles {
    my ($profile_spec) = @_;

    # for drivers we've not loaded yet
    $DBI::shared_profile = ($profile_spec)
        ? DBI::Profile->_auto_new($profile_spec) # XXX not documented
        : undef;

    # for any existing handles
    DBI->visit_handles(sub {
        shift->{Profile} = $DBI::shared_profile;
        return 1; # keep going to visit all
    });

    return $DBI::shared_profile;
}


1;
__END__

=head1 NAME

Plack::Middleware::Debug::DBIProfile - DBI::Profile panel

=head1 VERSION

version 0.102

=head1 SYNOPSIS

    enable 'Debug::DBIProfile'

is the same as:

    enable 'Debug::DBIProfile', profile => 1;

Using C<1> is very cheap, hence the default, but you'll find C<<profile => 2>>
much more interesting!

=head1 DESCRIPTION

Enables DBI::Profile on all DBI handles for the duration of the request.

The C<profile> parameter specifies the 'profile path'. It may be an integer or
a string.  The default is 1, which simply measures the time spent inside the
DBI.  For more detail try C<<profile => 2>> (or C<<profile => "!Statement">>)
to get a per-statement breakdown.
See L<DBI::Profile/ENABLING A PROFILE> for more information.

The Panel tab shows a summary of the profile data. For example:

    DBI Profile
    0.227 s (14%) #5

Where C<0.227> is the time spent within the DBI during this request.
And C<14%> is that time expressed as a percentage of the total time spent
handling the request (from the perspective of this middleware).
And the C<#5> shows the number of items in the profile results, if greater than
one. For example, with profile set to 2, the number reflects the number of
distinct statements profiled.

The Panel contents show the profile results.

=head1 NOTES

Prior to DBI 1.616, using DBI profiling while also using DBI tracing with the
"SQL" flag, you'll find extra "dbi_profile" lines will be written into the DBI log.

=head1 SEE ALSO

L<Plack::Middleware::Debug> and
L<Plack::Middleware::Debug::DBITrace>

=cut