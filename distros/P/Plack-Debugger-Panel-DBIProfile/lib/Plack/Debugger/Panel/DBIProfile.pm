use strict;
use warnings;
package Plack::Debugger::Panel::DBIProfile;
$Plack::Debugger::Panel::DBIProfile::VERSION = '0.01';

use parent 'Plack::Debugger::Panel';
use DBI::Profile;
use Time::HiRes qw(gettimeofday tv_interval);

my $DBI_PROFILE_FORMAT = '%1$s XXX %11$fs / %10$d = %2$fs avg (first %12$fs, min %13$fs, max %14$fs)';

sub new {
    my $class = shift;
    my %args  = @_ == 1 && ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

    $args{'title'} ||= 'DBI Profile';

    my $dbi_profile        = delete $args{dbi_profile} || 6;
    my $dbi_profile_format = delete $args{dbi_profile_format} || $DBI_PROFILE_FORMAT;

    # This is the JS formatter function that places the data in the panel.
    # https://metacpan.org/source/STEVAN/Plack-Debugger-0.03/example/app.psgi has some examples of formatters
    # The JS source is at $app/debugger/static/js/plack-debugger.js - search for 'formatters'
    # Options available are: pass_through, generic_data_formatter, ordered_key_value_pairs,
    # simple_data_table, simple_data_table_w_headers, multiple_data_table, multiple_data_table_w_headers,
    # ordered_keys_with_nested_data, nested_data, subrequest_formatter
    $args{'formatter'} ||= 'simple_data_table';


    $args{'before'} = sub {
        my ($self, $env) = @_;
        my $profile_obj = _set_profile_on_all_dbi_handles($dbi_profile);
        $self->stash({ start => [ gettimeofday ], profile_obj => $profile_obj});
    };

    $args{'after'} = sub {
        my ($self, $env, $resp) = @_;

        my $start   = $self->stash->{start};
        my $end     = [ gettimeofday ];
        my $elapsed = tv_interval( $start, $end );

        $self->set_subtitle( $elapsed );

        if (my $profile_obj = $self->stash->{profile_obj}) {
            #my $duration = gettimeofday() - $start_time;
            my $time_in_dbi = dbi_profile_merge_nodes(my $totals=[], $profile_obj->{Data});

            # 'Profile Path: %1$s XXX Profile Data: %11$fs / %10$d = %2$fs avg (first %12$fs, min %13$fs, max %14$fs)'
            my @items = $profile_obj->as_text({
                format => $dbi_profile_format,
                sortsub => sub {
                    my $ary = shift;
                    @$ary = sort { $b->[0][1] <=> $a->[0][1] } @$ary;
                },
            });

            my $i = 1; my $n;
            my @rows = map {[$i++ %2 ? do {$n = $i * 0.5; "<b>$n. $_</b>"} : '&nbsp;' x 6 . $_]}
                       map {split /XXX/} @items;

            $self->set_result( [ @rows ] );

            my $subtitle = sprintf "%.3f s (%d%%)",
                $time_in_dbi, ($elapsed) ? $time_in_dbi/$elapsed*100 : "-";
            # only show item count if >1 because they'll always be one
            # for profile==1, the default, so it's only noise, and for other
            # profile levels they'll always be an extra 'empty' item for
            # calls that can't be associated with a particular statement etc.
            $subtitle .= " #".@items if @items > 1;
            $self->set_subtitle($subtitle);

            # disable profiling and silently discard profile data
            local $DBI::Profile::ON_DESTROY_DUMP = sub { };
            _set_profile_on_all_dbi_handles(undef);
        }
    };

    $class->SUPER::new( \%args );
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

=pod

=encoding UTF-8

=head1 NAME

Plack::Debugger::Panel::DBIProfile

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    my $debugger = Plack::Debugger->new(
        panels => [
            Plack::Debugger::Panel::DBIProfile->new(),
            ... etc.
        ],

=head1 DESCRIPTION

This piece of blatant thievery is a port of L<Plack::Middleware::Debug::DBIProfile>
to L<Plack::Debugger>.

=head2 C<new>

Accepts two optional parameters in addition to those documented in L<Plack::Debugger>.

=over 4

=item C<dbi_profile>

Default: 6

See L<https://metacpan.org/pod/DBI::Profile#ENABLING-A-PROFILE>.

=item C<dbi_profile_format>

Default: C<%1$s XXX %11$fs / %10$d = %2$fs avg (first %12$fs, min %13$fs, max %14$fs>

See L<https://metacpan.org/pod/DBI::Profile#as_text>, but note that the format must
include 'XXX'. We split on the XXX and place the pair in succeeding rows of the
debugger panel.

=back

=head1 AUTHOR

Dave Baird <dave@zerofive.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by David R. Baird.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
