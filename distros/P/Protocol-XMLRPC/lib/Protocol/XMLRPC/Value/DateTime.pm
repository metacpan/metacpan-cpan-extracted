package Protocol::XMLRPC::Value::DateTime;

use strict;
use warnings;

use base 'Protocol::XMLRPC::Value';

require Time::Local;

sub type {'datetime'}

sub parse {
    my $class = shift;
    my ($datetime) = @_;

    my ($year, $month, $mday, $hour, $minute, $second) =
      ($datetime =~ m/(\d\d\d\d)(\d\d)(\d\d)T(\d\d):(\d\d):(\d\d)/);

    die "Invalid 'Datetime' value"
      unless defined $year
          && defined $month
          && defined $mday
          && defined $hour
          && defined $minute
          && defined $second;

    my $epoch;

    # Prevent crash
    eval {
        $epoch =
          Time::Local::timegm($second, $minute, $hour, $mday, --$month, $year);
        1;
    } or do {
        die "Invalid 'DateTime' value";
    };

    die "Invalid 'DateTime' value" if $epoch < 0;

    return $class->new($epoch);
}

sub to_string {
    my $self = shift;

    my $value = $self->value;

    my ($second, $minute, $hour, $mday, $month, $year, $wday) = gmtime($value);

    $year += 1900;
    $month++;

    #19980717T14:08:55
    $value = sprintf('%d%02d%02dT%02d:%02d:%02d',
        $year, $month, $mday, $hour, $minute, $second);

    return "<dateTime.iso8601>$value</dateTime.iso8601>";
}

1;
__END__

=head1 NAME

Protocol::XMLRPC::Value::DateTime - XML-RPC array

=head1 SYNOPSIS

    my $datetime = Protocol::XMLRPC::Value::DateTime->new(1234567890);
    my $datetime = Protocol::XMLRPC::Value::DateTime->parse('19980717T14:08:55');

=head1 DESCRIPTION

XML-RPC dateTime.iso8601

=head1 METHODS

=head2 C<new>

Creates new L<Protocol::XMLRPC::Value::DateTime> instance. Accepts unix epoch
time.

=head2 C<parse>

Parses dateTime.iso8601 string and creates a new L<Protocol::XMLRPC:::Value::Base64>
instance.

=head2 C<type>

Returns 'datetime'.

=head2 C<value>

    my $datetime = Protocol::XMLRPC::Value::DateTime->new(1234567890);
    # $datetime->value returns 20091302T23:31:30

Returns serialized Perl5 scalar.

=head2 C<to_string>

    my $datetime = Protocol::XMLRPC::Value::DateTime->new(1234567890);
    # $datetime->to_string is now '<dateTime.iso8601>20091302T23:31:30</dateTime.iso8601>'

XML-RPC datetime string representation.
