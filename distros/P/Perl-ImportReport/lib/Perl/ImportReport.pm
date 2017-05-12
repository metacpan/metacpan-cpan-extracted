package Perl::ImportReport;

use strict;
use warnings;

use PPI       ();
use PPI::Util ();

$Perl::ImportReport::VERSION = '0.1';

sub new {
    my $ppi = PPI::Util::_Document( $_[1] ) || return;

    return bless {
        'ppi_document'  => $ppi,
        'import_report' => undef,
      },
      $_[0];
}

sub get_ppi_document {
    return $_[0]->{'ppi_document'};
}
*Document = *get_ppi_document;    # to match Perl::MinimumVersion

sub get_import_report {
    my $iro = shift;

    # restart fresh
    $iro->{'import_report'} = undef;

    # Create a map of all PPI::Statement::Package's so we can determine what package a given PPI::Statement::Include is in
    my %pkg = ( 0 => [ { 'namespace' => 'main', 'column_number' => 0 } ] );
    my $pkg_nodes = $iro->{'ppi_document'}->find(
        sub {
            if ( $_[1]->isa('PPI::Statement::Package') ) {
                if ( my $ns = $_[1]->namespace() ) {
                    my $line_no = $_[1]->line_number();
                    $pkg{$line_no} = [] if !exists $pkg{$line_no};

                    push @{ $pkg{$line_no} },
                      {
                        'namespace'     => $ns,
                        'column_number' => $_[1]->column_number(),
                      };
                    return 1;
                }
            }
            return;
        }
    );

    $iro->{'import_report'}{'number_of_includes'} = 0;
    if ( $iro->{'ppi_document'}->find_any('PPI::Statement::Include') ) {
        my $inc_nodes = $iro->{'ppi_document'}->find(
            sub {
                if ( $_[1]->isa('PPI::Statement::Include') && !$_[1]->pragma && $_[1]->module && $_[1]->type eq 'use' ) {
                    return 1;
                }
                return;
            }
        );

        return $iro->{'import_report'} if ref($inc_nodes) ne 'ARRAY';

        my @incs;
        for my $ppi_inc ( @{$inc_nodes} ) {
            
            my $parent_package;
            for my $line_num ( sort { $a <=> $b } keys %pkg ) {
                if ( $line_num <= $ppi_inc->line_number() ) {
                    if ( $line_num == $ppi_inc->line_number() ) {
                        for my $ns_hr ( @{ $pkg{$line_num} } ) {
                            if ( $ns_hr->{'column_number'} < $ppi_inc->column_number() ) {
                                $parent_package = $ns_hr->{'namespace'};
                            }
                        }
                    }
                    else {
                        $parent_package = $pkg{$line_num}->[-1]{'namespace'};
                    }
                }
            }

            my %import_data = (
                'raw_perl'       => "$ppi_inc",
                'module'         => $ppi_inc->module(),
                'module_version' => $ppi_inc->module_version(),
                'arguments'      => [ $ppi_inc->arguments() ],
                'line_number'    => $ppi_inc->line_number(),
                'in_package'     => $parent_package,
                'exporter'       => {},
            );

            my $module = $ppi_inc->module();
            if ( !defined $ppi_inc->arguments() ) {
                eval "require $module;";    # TODO: ? PPI $module instead so as not to run code  ?...
                no strict 'refs';
                $import_data{'exporter'}{'EXPORT'}{'error'} = $@;
                $import_data{'exporter'}{'EXPORT'}{'count'} = @{"$module\::EXPORT"};
                @{ $import_data{'exporter'}{'EXPORT'}{'data'} } = @{"$module\::EXPORT"};

                $import_data{'symbol_list'} = \@{"$module\::EXPORT"};
                push @{ $iro->{'import_report'}{'imports'} }, \%import_data;
                $iro->{'import_report'}{'number_of_includes'}++;
            }
            else {
                my $list = join( '', map { $_->content() } $ppi_inc->arguments() );

                if ( $list !~ m/^\s*\(/ ) {
                    $list = "($list)";
                }

                my @list = do { no strict; eval $list };
                my @expanded = @list;

                if (@list) {

                    # If any of the entries in an import list begins with !, : or / then the list is treated
                    # as a series of specifications which either add to or delete from the list of names to
                    # import. They are processed left to right. Specifications are in the form:
                    #     [!]name         This name only
                    #     [!]:DEFAULT     All names in @EXPORT
                    #     [!]:tag         All names in $EXPORT_TAGS{tag} anonymous list
                    #     [!]/pattern/    All names in @EXPORT and @EXPORT_OK which match

                    # TODO: @list contains only qr()
                    if ( grep m{^[!:/]}, @list ) {
                        eval "require $module;";
                        no strict 'refs';

                        $import_data{'exporter'}{'EXPORT_OK'}{'error'} = $@;
                        @{ $import_data{'exporter'}{'EXPORT_OK'}{'data'} } = @{"$module\::EXPORT_OK"};

                        $import_data{'exporter'}{'EXPORT_TAGS'}{'error'} = $@;
                        $import_data{'exporter'}{'EXPORT_TAGS'}{'data'}  = \%{"$module\::EXPORT_TAGS"};    # TOOD: ? copy ?

                        @expanded = ();

                        for my $ent (@list) {
                            my $symbol = $ent;
                            my $remove = 0;
                            if ( $ent =~ m/^\!(.*)/ ) {
                                $remove = 1;
                                $symbol = $1;
                            }

                            my @symbols;

                            if ( substr( $symbol, 0, 1 ) eq ':' ) {
                                if ( exists ${"$module\::EXPORT_TAGS"}{$symbol} ) {
                                    @symbols = @{ ${"$module\::EXPORT_TAGS"}{$symbol} };
                                }
                                else {
                                    my $copy = $symbol;
                                    $copy =~ s/^://;
                                    if ( exists ${"$module\::EXPORT_TAGS"}{$copy} ) {
                                        @symbols = @{ ${"$module\::EXPORT_TAGS"}{$copy} };
                                    }
                                }

                            }
                            elsif ( ref($symbol) eq 'Regexp' || substr( $symbol, 0, 1 ) eq '/' ) {
                                my $qr = $symbol;
                                if ( ref($symbol) ne 'Regexp' ) {
                                    my $copy = $symbol;
                                    $copy =~ s{^\/}{};
                                    $copy =~ s{\/$}{};
                                    $qr = qr($copy);
                                }

                                @symbols = grep $qr, @{"$module\::EXPORT_OK"};
                                push @symbols, map { $_ =~ $qr ? @{ ${"$module\::EXPORT_TAGS"}{$_} } : () } keys %{"$module\::EXPORT_TAGS"};
                            }
                            else {
                                @symbols = ($symbol);
                            }

                            # TODO: normalize sigil-prefixed names in some sensical manner
                            if ($remove) {
                                my %remove;
                                @remove{@symbols} = ();
                                @expanded = map { exists $remove{$_} ? () : ($_) } @expanded;
                            }
                            else {
                                push @expanded, @symbols;
                            }
                        }
                    }

                    $import_data{'symbol_list'} = \@expanded;
                    push @{ $iro->{'import_report'}{'imports'} }, \%import_data;
                    $iro->{'import_report'}{'number_of_includes'}++;
                }
            }
        }
    }

    return $iro->{'import_report'};
}

1;

__END__

=head1 NAME

Perl::ImportReport - Find data on symbols being imported by Perl code

=head1 VERSION

This document describes Perl::ImportReport version 0.1

=head1 SYNOPSIS

    use Perl::ImportReport;
    
    # Create the import checking object
    my $object = Perl::ImportReport->new( $filename ) || die "Invalid value for PPI document source";
    my $object = Perl::ImportReport->new( \$source  ) || die "Invalid value for PPI document source";
    my $object = Perl::ImportReport->new( $ppi_document ) || die "Invalid value for PPI document source";

    # Find the import data information
    my $import_data = $object->get_import_report();  

=head1 DESCRIPTION

Sometimes you want to trim out needless importing from your code. This object calculates and 
reports what packages are importing what symbols into what packages in the code.

=head1 INTERFACE 

=head2 new

  # Create the version checking object
  my $object = Perl::ImportReport->new( $filename ) || die "Invalid value for PPI document source";
  my $object = Perl::ImportReport->new( \$source  ) || die "Invalid value for PPI document source";
  my $object = Perl::ImportReport->new( $ppi_document ) || die "Invalid value for PPI document source";

The C<new> constructor creates a new import reporting object for a
L<PPI::Document>. You can also provide the document to be read as a
file name, or as a C<SCALAR> reference containing the code.

Returns a new C<Perl::ImportReport> object, or C<undef> on error.

=head2 get_ppi_document

The C<get_ppi_document> accessor can be used to get the L<PPI::Document> object back out of the import reporting.

=head2 Document

Alias for C<get_ppi_document> for all you L<Perl::MinimumVersion> fans.

=head2 get_import_report

Dive the PPI PDOM and build a report of the symbols being imported in the code.

Returns a data structure with the following keys:

=over 4

=item 'number_of_includes'

In the context of this module an "include" is a use() statement that is not a pragma and not a non-import use().

=item 'imports'

This is an array of hashes. Each hash describes an "include" instance.

The keys in this hash are:

=over 4

=item 'symbol_list'

Expanded export list. Tags, negations, and regexes are worked out into the final list of what would actually be exported.

=item 'raw_perl' 

The actual use() statement in question.

=item 'module' 

The namespace of the module.

=item 'module_version'

The version being required (if any)

=item 'arguments'

The array ref containing arguments()

=item 'line_number'

The line number of the use statement.

=item 'in_package'

The package it is in (and thus where the symbols will be imported into).

=item 'exporter' 

A hashref with the keys EXPORT, EXPORT_OK, EXPORT_TAG.

Each one of those is a hash that has the key 'error' which holds the error (if any() trying to require the module), 
'data' that hold the modules's corresponding symbol. (e.g. {EXPORT}{data}) is the module's @EXPORT) 

EXPORT also has 'count' which is the count of items in @EXPORT.

=back

=back 

=head1 DIAGNOSTICS

Throws no warnings or errors of it's own.

=head1 CONFIGURATION AND ENVIRONMENT

Perl::ImportReport requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<PPI>, L<PPI::Util>

=head1 SEE ALSO

L<Perl::MinimumVersion>

=head1 TODO

There a couple of possible todo's commented in the source, patches welcome!

Have the results data structure as an object (or objects) that have their own inspection methods and/or add inspection methods.

For now you can find a simple reporting script that uses the data structure directly at L<"http://drmuey.com/?do=page&id=102">.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-perl-importreport@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

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
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
