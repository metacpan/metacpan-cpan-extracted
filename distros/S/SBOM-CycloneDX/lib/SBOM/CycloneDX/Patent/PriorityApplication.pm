package SBOM::CycloneDX::Patent::PriorityApplication;

use 5.010001;
use strict;
use warnings;
use utf8;

use SBOM::CycloneDX::Timestamp;

use Types::Standard qw(Str InstanceOf);

use Moo;
use namespace::autoclean;

extends 'SBOM::CycloneDX::Base';


has application_number => (is => 'rw', isa => Str, required => 1);

has jurisdiction => (is => 'rw', isa => Str, required => 1);

has filing_date => (
    is       => 'rw',
    isa      => InstanceOf ['SBOM::CycloneDX::Timestamp'],
    coerce   => sub { ref($_[0]) ? $_[0] : SBOM::CycloneDX::Timestamp->new($_[0]) },
    required => 1
);


sub TO_JSON {

    my $self = shift;

    my $json = {};

    $json->{applicationNumber} = $self->application_number if ($self->application_number);
    $json->{jurisdiction}      = $self->jurisdiction       if ($self->jurisdiction);
    $json->{filingDate}        = $self->filing_date        if ($self->filing_date);

    return $json;

}

1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Patent::PriorityApplication - Priority Application

=head1 SYNOPSIS

    SBOM::CycloneDX::Patent::PriorityApplication->new();


=head1 DESCRIPTION

L<SBOM::CycloneDX::Patent::PriorityApplication> The priorityApplication
contains the essential data necessary to identify and reference an earlier
patent filing for priority rights. In line with WIPO ST.96 guidelines, it
includes the jurisdiction (office code), application number, and filing
date-the three key elements that uniquely specify the priority application
in a global patent context.

=head2 METHODS

L<SBOM::CycloneDX::Patent::PriorityApplication> inherits all methods from L<SBOM::CycloneDX::Base>
and implements the following new ones.

=over

=item SBOM::CycloneDX::Patent::PriorityApplication->new( %PARAMS )

Properties:

=over

=item * C<application_number>, The unique number assigned to a patent application 
when it is filed with a patent office. It is used to identify the specific 
application and track its progress through the examination process. Aligned 
with C<ApplicationNumber> in ST.96. Refer to L<ApplicationIdentificationType in ST.96|https://www.wipo.int/standards/XMLSchema/ST96/V8_0/Patent/ApplicationIdentificationType.xsd>. 

=item * C<filing_date>, The date the patent application was filed with the
jurisdiction. Aligned with C<FilingDate> in WIPO ST.96. Refer to
L<FilingDate in ST.96|https://www.wipo.int/standards/XMLSchema/ST96/V8_0/Patent/FilingDate.xsd>.

=item * C<jurisdiction>, The jurisdiction or patent office where the priority 
application was filed, specified using WIPO ST.3 codes. Aligned with 
C<IPOfficeCode> in ST.96. Refer to L<WIPOfficeCode in ST.96|https://www.wipo.int/standards/XMLSchema/ST96/V8_0/Common/IPOfficeCode.xsd>.

=back

=item $priority_application->application_number

=item $priority_application->filing_date

=item $priority_application->jurisdiction

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-SBOM-CycloneDX/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-SBOM-CycloneDX>

    git clone https://github.com/giterlizzi/perl-SBOM-CycloneDX.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025-2026 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
