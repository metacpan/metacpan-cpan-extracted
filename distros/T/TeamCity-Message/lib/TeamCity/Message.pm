package TeamCity::Message;

use strict;
use warnings;

our $VERSION = '0.02';

use Time::HiRes qw( time );

use Exporter qw( import );

## no critic (Modules::ProhibitAutomaticExportation)
our @EXPORT = qw( tc_message );
## use critic
our @EXPORT_OK = ( @EXPORT, 'tc_timestamp' );

sub tc_message {
    my %args = @_;

    my $type = delete $args{type} || 'message';
    my $content = delete $args{content}
        or die 'You must provide a content argument to tc_message()';

    my $msg = "##teamcity[$type";

    if ( ref $content ) {
        for my $name ( sort keys %{$content} ) {
            my $value = $content->{$name};
            $msg .= qq{ $name='} . _escape($value) . q{'};
        }

        $msg .= q{ timestamp='} . tc_timestamp() . q{'}
            unless $content->{timestamp};
    }
    else {
        $msg .= q{ '} . _escape($content) . q{'} or die $!;
    }

    $msg .= "]\n";

    return $msg;
}

sub tc_timestamp {
    my $now = time;
    my ( $s, $mi, $h, $d, $mo, $y ) = ( gmtime($now) )[ 0 .. 5 ];

    my $float = ( $now - int($now) );
    return sprintf(
        '%4d-%02d-%02dT%02d:%02d:%02d.%03d',
        $y + 1900, $mo + 1, $d,
        $h, $mi, $s,

        # We only need 3 places of precision so if we multiply it by 1,000 we
        # can just treat it as an integer.
        $float * 1000,
    );
}

sub _escape {
    my $str = shift;

    ( my $esc = $str ) =~ s{(['|\]])}{|$1}g;
    $esc =~ s{\n}{|n}g;
    $esc =~ s{\r}{|r}g;

    return $esc;
}

1;

# ABSTRACT: Generate TeamCity build messages

__END__

=pod

=encoding UTF-8

=head1 NAME

TeamCity::Message - Generate TeamCity build messages

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use TeamCity::Message;

  print STDOUT tc_message(
      type    => 'message',
      content => { text => 'This is a build message.' },
  );

  print STDOUT tc_message(
      type    => 'message',
      content => {
          text   => 'This is a serious build message.',
          status => 'ERROR',
      },
  );

  print STDOUT tc_message(
      type    => 'progressMessage',
      content => 'This is a progress message',
  );

=head1 DESCRIPTION

This module generates TeamCity build messages.

See
L<https://confluence.jetbrains.com/display/TCD9/Build+Script+Interaction+with+TeamCity#BuildScriptInteractionwithTeamCity-reportingMessagesForBuildLogReportingMessagesForBuildLog>
for more details on TeamCity build messages.

=head1 API

=head2 tc_message(...)

Exported by default, this subroutine can be used to generate properly formatted
and escaped TeamCity build message.

This subroutine accepts the following arguments:

=over 4

=item * type

This is the message type, such as "message", "testStarted", "testFinished",
etc.

This is required.

=item * content

This can be either a string or a hash reference of key/value pairs. This will
be turned into the content of the message.

This is required.

=back

When the C<content> parameter is a hash reference, this subroutine will always
add a "timestamp" to the message matching the current time. You can provide an
explicit C<timestamp> value in the C<content> if you want to set this
yourself.

=head2 tc_timestamp()

Exported on demand, this subroutine will return a string containing the current
timestamp formatted suitably for consumption by TeamCity.  You can pass this
to the C<tc_message(...)> function like so:

    my $remembered_timestamp = tc_timestamp();

    # ...time passes...

    print STDOUT tc_message(
        type    => 'message',
        content => {
            text => 'This is a build message.',
            timestamp => $remembered_timestamp,
        }
    );

=head1 SUPPORT

Please report all issues with this code using the GitHub issue tracker at
L<https://github.com/maxmind/TeamCity-Message/issues>.

Bugs may be submitted through L<https://github.com/maxmind/TeamCity-Message/issues>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 CONTRIBUTORS

=for stopwords Dave Rolsky Mark Fowler

=over 4

=item *

Dave Rolsky <drolsky@maxmind.com>

=item *

Mark Fowler <mark@twoshortplanks.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by MaxMind, Inc..

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
