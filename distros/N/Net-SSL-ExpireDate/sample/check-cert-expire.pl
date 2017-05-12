#!/usr/bin/env perl

use strict;
use warnings;
use Carp;
use Getopt::Long;
use Pod::Usage;
use Data::Dumper;

use Net::SSL::ExpireDate;
use Regexp::Common qw(net);
use YAML;
use URI::Escape;
# use Smart::Comments;

MAIN: {
    my %opt;
    Getopt::Long::Configure("bundling");
    GetOptions(\%opt,
               'duration|d=s',
               'file|f=s',
               'link|l',
               'help|h|?') or pod2usage(-verbose=>1);
    pod2usage(-verbose=>1) if exists $opt{'help'};
    pod2usage("missing option: --file") unless exists $opt{'file'};

    ### %opt
    open my $file, '<', $opt{'file'}
        or croak "$opt{'file'}: $!";
    chomp (my @testee = <$file>);
    close $file;
    ### @testee

    my $duration = exists $opt{'duration'} ? $opt{'duration'} : undef;
    ### $duration

    my $output = {
        title => 'Certificate Expire Date',
        entry => [],
    };

    for my $t (@testee) {
        next if $t =~ /^#/;
        next if $t =~ /^$/;
        ### testee: $t
        my $ed = Net::SSL::ExpireDate->new( build_arg($t) );
        if ($ed->is_expired($duration)) {
            ### expired: $ed->expire_date->iso8601
            push @{$output->{entry}}, {
                title => $t . ($duration ? " (expire within $duration)" : ''),
                date  => $ed->expire_date->iso8601,
            };
            ${ $output->{entry} }[-1]->{link} = mk_link($ed, $duration) if $opt{'link'};
        }
    }

    print YAML::Dump $output;

    exit 0;
}

sub build_arg {
    my ($v) = @_;
    if ($v =~ m{^(file)://(.+)}) {
        return $1 => $2;
    } elsif ($v =~ m{^(https)://([^/]+)}) {
        return $1 => $2;
    } elsif ($v =~ m{^$RE{net}{domain}{-nospace}{-keep}$}) {
        return 'https' => $1;
    } elsif (-r $v) {
        return 'file' => $v;
    } else {
        croak "$v: assume file. but cannot read.";
    }
}

sub mk_link {
    my ($ed, $duration) = @_;
    $ed->type . '://' . $ed->target . ($duration ? '#' . uri_escape($duration) : '');
}

__END__

=head1 NAME

B<check-cert-expire.pl> - check and list expired certificates

=head1 SYNOPSIS

B<check-cert-expire.pl> [ B<--help> ] [ B<--duration> DURATION ] B<--file> DATAFILE

  $ cat <<EOF > server-list.txt
  https://rt.cpan.org
  https://www.google.com
  EOF
  
  $ check-cert-expire.pl --duration '3 months' --file server-list.txt
  $ check-cert-expire.pl -d         '3 months' -f     server-list.txt
  ---
  entry:
    - date: 2015-04-14T05:12:17
      title: https://rt.cpan.org
  title: Certificate Expire Date

=head1 DESCRIPTION

Examine expire date of certificate and output name and expire date if expired.
Output format is YAML.

Examinee certificate is both OK via network (HTTPS) and local file.

=head1 OPTIONS

=over 4

=item B<--file> DATAFILE

=item B<-f> DATAFILE

DATAFILE is name of plain text file contains testee list.

Acceptable list format is the following.

  FORMAT        EXAMPLE
  ===============================
  https://FQDN  https://rt.cpan.org
  file://PATH   file:///etc/ssl/cert.pem
  FQDN          rt.cpan.org
  PATH          /etc/ssl/cert.pem

=item B<--duration> DURATION

=item B<-d> DURATION

Specify the furtur point to check expiration.
If omitted, check against just now.

DURATION accepts human readable text. See also L<Time::Duration::Parse|Time::Duration::Parse>.

  3 days
  4 months
  10 years
  4 months and 3days

=item B<--link>

=item B<-l>

Add dummy link attribute.

=back

=head1 SEE ALSO

L<Net::SSL::ExpireDate|Net::SSL::ExpireDate>,
L<Time::Duration::Parse|Time::Duration::Parse>

=head1 AUTHOR

HIROSE, Masaaki E<lt>hirose31@gmail.comE<gt>

=cut

# for Emacsen
# Local Variables:
# mode: cperl
# cperl-indent-level: 4
# indent-tabs-mode: nil
# End:

# vi: set ts=4 sw=4 sts=0 :
