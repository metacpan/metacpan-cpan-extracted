#!/usr/bin/perl

package Net::CVE;

use 5.014002;
use warnings;

our $VERSION = "0.006"; # 20230606

use Carp;
use HTTP::Tiny;
use JSON::MaybeXS;
use List::Util qw( first );

# https://cveawg.mitre.org/api/cve/CVE-2022-26928
# But that is likely to change to cve.org

sub Version { $VERSION }

sub new {
    my $class = shift;
    my %r = (
	url  => "https://cveawg.mitre.org/api/cve",
	ua   => undef,
	lang => "en",
	data => {},
	diag => undef,
	);
    if (@_) {
	if (@_ == 1 && ref $_[0] eq "HASH") {
	    $r{$_} = $_[0]{$_} for keys %{$_[0]};
	    }
	elsif (@_ == 2) {
	    my %p = @_;
	    $r{$_} = $p{$_} for keys %p;
	    }
	}
    bless \%r => $class;
    } # new

sub diag {
    my $self = shift or return;
    ref $self or return;
    my $d = $self->{diag} or return;
    unless (defined wantarray) { # void context
	my $act = $d->{action};
	warn "$act: ",
	    (join " " => grep { length } $d->{status}, $d->{reason}), "\n";
	$act =~ s/./ /g;
	warn "$act  source = $d->{source}\n"	if $d->{source};
	warn "$act  usage: $d->{usage}\n"	if $d->{usage};
	}
    return $d;
    } # diag

sub get {
    my ($self, $cve) = @_;
    ref $self or $self = __PACKAGE__->new ();
    $self->{data} = {};
    $self->{diag} = undef;
    $cve or return $self;
    $cve =~ s/^(?=[0-9])/CVE-/;
    if ($cve =~ m/^CVE-[0-9]{4}-([0-9]+)$/) {
	$self->{ua} //= HTTP::Tiny->new ();
	my $url = join "/" => $self->{url}, $cve;
	my $r = $self->{ua}->get ($url);
	unless ($r->{success}) {
	    # if pseudo-HTTP status code 599 and reason "Internal Exception"
	    # the content field will contain the text of the error
	    my $status = $r->{status};
	    my $reason = join ": " => grep { length }
		$r->{reason}, $status =~ m/^5[0-9][0-9]$/ ? $r->{content} : "";
	    $self->{diag} = {
		status => $status,
		reason => $reason,
		action => "get",
		source => $url,
		usage  => undef,
		};
	    return $self;
	    }
	$self->{data} = decode_json ($r->{content});
	}
    elsif (-s $cve) {
	my $fh;
	unless (open $fh, "<:encoding(utf-8)", $cve) {
	    $self->{diag} = {
		status => 0 + $!,
		reason => "$!",
		action => "get",
		source => $cve,
		usage  => 'get ("cve-2022-26928.json")',
		};
	    return $self;
	    }
	unless (eval { $self->{data} = decode_json (do { local $/; <$fh> }); 1 }) {
	    $self->{diag} = {
		status => -2,
		reason => $@ =~ s{\s+at\s+\S+\s+line\s+\d+.*}{}rs,
		action => "decode_json",
		source => $cve,
		usage  => undef,
		};
	    return $self;
	    }
	close $fh;
	}
    else {
	#warn "Invalid CVE format: '$cve' - expected format CVE-2023-12345\n";
	$self->{diag} = {
	    status => -1,
	    reason => "Invalid CVE format: '$cve'",
	    action => "get",
	    source => "tag",
	    usage  => 'get ("CVE-2022-26928")',
	    };
	return $self;
	}
    $self;
    } # get

sub data {
    my $self = shift;
    ref $self or $self = __PACKAGE__->new ();
    @_ and $self->get (@_);
    $self->{data};
    } # data

sub summary {
    my $self = shift;
    ref $self or $self = __PACKAGE__->new ();
    @_ and $self->get (@_);
    my $j   = $self->{data}         or croak "summary only available after get";
    my $cna = $j->{containers}{cna} or return +{};
    #y $weak     = ... weaknesses [{ description [{ lang => "en", value => "CWE-123"}]

    my $severity = join ", " => grep { length } map { $_->{cvssV3_1}{baseSeverity}            } @{$cna->{metrics}      || []};
    my $score    = join ", " => grep { length } map { $_->{cvssV3_1}{baseScore}               } @{$cna->{metrics}      || []};

    my %desc;
    for (@{$cna->{descriptions} || []}) {
	my $d = $_->{value} or next;
	push @{$desc{$_->{lang}}} => $d;
	}
    my @lang     = sort keys %desc;
    my $lang     = first { m/\b $self->{lang} /ix } @lang;
       $lang   //= first { m/\b  en           /ix } @lang;
       $lang   //= $lang[0];
    my $desc     = join "\n" => @{$desc{$lang}};

    my %problem;
    for (map { @{$_->{descriptions} || []} } @{$cna->{problemTypes} || []}) {
	my $d = $_->{description} or next;
	push @{$problem{$_->{lang}}} => $d;
	}
    @lang       = sort keys %problem;
    $lang       = first { m/\b $self->{lang} /ix } @lang;
    $lang     //= first { m/\b  en           /ix } @lang;
    $lang     //= $lang[0];
    my $problem = join "\n" => @{$problem{$lang}};

    {	id          => $j->{cveMetadata}{cveId},
	date        => $j->{cveMetadata}{datePublished},
	description => $desc,
	severity    => lc $severity,
	score       => $score,
	problem     => $problem,
	product     => [ $self->product   ],
	vendor      => [ $self->vendor    ],
	platforms   => [ $self->platforms ],
	status      =>   $self->status,
	};
    } # summary

sub status {
    my $self = shift;
    @_ and $self->get (@_);
    my $j   = $self->{data} or croak "status only available after get";
    $j->{cveMetadata}{state};
    } # status

sub _affected_tag {
    my ($self, $tag) = @_;
    my $j   = $self->{data}         or croak "$tag only available after get";
    my $cna = $j->{containers}{cna} or return;
    my %v = map { $_->{$tag} => 1 } @{$cna->{affected} || []};
    my @v = sort keys %v;
    return wantarray ? @v : join ", " => @v;
    } # _affected_tag

sub _affected_tag_a {
    my ($self, $tag) = @_;
    my $j   = $self->{data}         or croak "$tag only available after get";
    my $cna = $j->{containers}{cna} or return;
    my %v = map { $_ => 1 } map { @{$_ || []} } map { $_->{$tag} }
	@{$cna->{affected} || []};
    my @v = sort keys %v;
    return wantarray ? @v : join ", " => @v;
    } # _affected_tag_a

sub platforms {
    my $self = shift;
    @_ and $self->get (@_);
    $self->_affected_tag_a ("platforms");
    } # platforms

sub vendor {
    my $self = shift;
    @_ and $self->get (@_);
    $self->_affected_tag ("vendor");
    } # vendor

sub product {
    my $self = shift;
    @_ and $self->get (@_);
    $self->_affected_tag ("product");
    } # vendor

1;

__END__

=head1 NAME

Net::CVE - Fetch CVE (Common Vulnerabilities and Exposures) information from cve.org

=head1 SYNOPSIS

 use Net::CVE;

 my $cr = Net::CVE->new ();

 $cr->get ("CVE-2022-26928");
 my $full_report = $cr->data;
 my $summary     = $cr->summary;

 $cr->diag;

 use Data::Peek;
 DDumper $cr->summary ("CVE-2022-26928");

=head1 DESCRIPTION

This module provides a Perl interface to retrieve information from the
L<CVE database|https://www.cve.org/Downloads> provided by L<https://cve.org>
based on a CVE tag.

=head1 METHODS

=head2 new

 my $reporter = CVE->new (
     url  => "https://cveawg.mitre.org/api/cve",
     ua   => undef,
     lang => "en",
     );

Instantiates a new object. All attributes are optional.

=over 2

=item url

Base url for REST API

=item ua

User agent. Needs to know about C<< ->get >>. Defaults to L<HTTP::Tiny>.
Initialized on first use.

 my $reporter = CVE->new (ua => HTTP::Tiny->new);

Other agents not yet tested, so they might fail.

=item lang

Set preferred language for L</summary>. Defaults to C<en>.

If the preferred language is present in descriptions use that. If it is not, use
C<en>. If that is also not present, use the first language found.

=back

=head2 get

 $reporter->get ("CVE-2022-26928");
 $reporter->get ("2022-26928");
 $reporter->get ("Files/CVE-2022-26928.json");

Fetches the CVE data for a given tag. On success stores the results internally.
Returns the object. The leading C<CVE-> is optional.

If the argument is a non-empty file, that is parsed instead of fetching the
information from the internet.

The decoded information is stored internally and will be re-used for other
methods.

C<get> returns the object and allows to omit a call to C<new> which will be
implicit but does not allow attributes

 my $reporter = Net::CVE->get ("2022-26928");

is a shortcut to

 my $reporter = Net::CVE->new->get ("2022-26928");

=head2 data

 my $info = $reporter->data;

Returns the data structure from the last successful fetch, C<undef> if none.

Giving an argument enables you to skip the L</get> call, which is implicit, so

 my $info = $reporter->data ("CVE-2022-26928");

is identical to

 my $info = $reporter->get ("CVE-2022-26928")->data;

or

 $reporter->get ("CVE-2022-26928");
 my $info = $reporter->data;

or even, whithout an object

 my $info = Net::CVE->data ("CVE-2022-26928");

=head2 summary

 my $info = $reporter->summary;
 my $info = $reporter->summary ("CVE-2022-26928");

Returns a hashref with basic information from the last successful fetch,
C<undef> if none.

Giving an argument enables you to skip the L</get> call, which is implicit, so

 my $info = $reporter->summary ("CVE-2022-26928");

is identical to

 my $info = $reporter->get ("CVE-2022-26928")->summary;

or

 $reporter->get ("CVE-2022-26928");
 my $info = $reporter->summary;

or even, whithout an object

 my $info = Net::CVE->summary ("CVE-2022-26928");

The returned hash looks somewhat like this

 { date        => "2022-09-13T18:41:25",
   description => "Windows Photo Import API Elevation of Privilege Vulnerability",
   id          => "CVE-2022-26928",
   problem     => "Elevation of Privilege",
   score       => "7",
   severity    => "high",
   status       => "PUBLISHED",
   vendor      => [ "Microsoft" ]
   platforms   => [ "32-bit Systems",
       "ARM64-based Systems",
       "x64-based Systems",
       ],
   product     => [
       "Windows 10 Version 1507",
       "Windows 10 Version 1607",
       "Windows 10 Version 1809",
       "Windows 10 Version 20H2",
       "Windows 10 Version 21H1",
       "Windows 10 Version 21H2",
       "Windows 11 version 21H2",
       "Windows Server 2016",
       "Windows Server 2019",
       "Windows Server 2022",
       ],
   }

As this is work in progress, likely to be changed

=head2 status

 my $status = $reporter->status;

Returns the status of the CVE, most likely C<PUBLISHED>.

=head2 vendor

 my @vendor  = $reporter->vendor;
 my $vendors = $reporter->vendor;

Returns the list of vendors for the affected parts of the CVE. In scalar
context a string where the (sorted) list of unique vendors is joined by
C<, > in list context the (sorted) list itself.

=head2 product

 my @product  = $reporter->product;
 my $products = $reporter->product;

Returns the list of products for the affected parts of the CVE. In scalar
context a string where the (sorted) list of unique products is joined by
C<, > in list context the (sorted) list itself.

=head2 platforms

 my @platform  = $reporter->platforms;
 my $platforms = $reporter->platforms;

Returns the list of platforms for the affected parts of the CVE. In scalar
context a string where the (sorted) list of unique platforms is joined by
C<, > in list context the (sorted) list itself.

=head2 diag

 $reporter->diag;
 my $diag = $reporter->diag;

If an error occured, returns information about the error. In void context
prints the diagnostics using C<warn>. The diagnostics - if any - will be
returned in a hashref with the following fields:

=over 2

=item status

Status code

=item reason

Failure reason

=item action

Tag of where the failure occured

=item source

The URL or filename leading to the failure

=item usage

Help message

=back

Only the C<action> field is guaranteed to be set, all others are optional.

=head1 BUGS

None so far

=head1 TODO

=over 2

=item Better error reporting

Obviously

=item Tests

There are none yet

=item Meta-stuff

Readme, Changelog, Makefile.PL, ...

=item Fallback to Net::NVD

Optionally. It does not (yet) provide vendor, product and platforms.
It however provides nice search capabilities.

=item RHSA support

Extend to return results for C<RHSA-2023:1791> type vulnerability tags.

 https://access.redhat.com/errata/RHSA-2023:1791
 https://access.redhat.com/hydra/rest/securitydata/crf/RHSA-2023:1791.json

The CRF API provides the list of CVE's related to this tag:

 my $url = "https://access.redhat.com/hydra/rest/securitydata/crf";
 my $crf = decode_json ($ua->get ("$url/RHSA-2023:1791.json"));
 my @cve = map { $_->{cve} }
           @{$crf->{cvrfdoc}{vulnerability} || []}

Will set C<@cve> to

 qw( CVE-2023-1945  CVE-2023-1999  CVE-2023-29533 CVE-2023-29535
     CVE-2023-29536 CVE-2023-29539 CVE-2023-29541 CVE-2023-29548
     CVE-2023-29550 );

See L<the API documentation|https://access.redhat.com/documentation/en-us/red_hat_security_data_api/1.0/html-single/red_hat_security_data_api/index>.

=back

=head1 SEE ALSO

=over 2

=item CVE search

L<https://cve.org> and L<https://cve.mitre.org/cve/search_cve_list.html>

=item L<Net::OSV>

Returns OpenSource Vulnerabilities.

=item CVE database

L<https://www.cvedetails.com/>

=back

=head1 AUTHOR

H.Merijn Brand <hmbrand@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2023-2023 H.Merijn Brand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. See L<perlartistic>.

This interface uses data from the CVE API but is not endorsed by any
of the CVE partners.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
