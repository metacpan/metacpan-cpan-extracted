package PGObject::Type::Composite;

use 5.008;
use Scalar::Util;
use PGObject::Util::Catalog::Types qw(get_attributes);
use PGObject::Util::PseudoCSV;
use Carp;

=head1 NAME

PGObject::Type::Composite - Composite Type handler for PGObject

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

  package MyObject;
  use Moo;
  with 'PGObject::Type::Composite';

Then

   use MyObject;
   my $dbh = DBI->connect;
   MyObject->initialize(dbh => $dbh);
   MyObject->register(registry => 'default', type => 'foo');

And now every column of type foo (which must be a composite type) will get
deserialized into MyObject.

=head1 EXPORTS

=over

=item initialize

=item from_db

=item to_db

=back

=cut

=head1 SUBROUTINES/METHODS

=head2 initialize

=head2 register

=head2 from_db

=head2 to_db

=cut

sub import {
    my ($importer) = caller;
    my @cols;
    my $can_has if *{ "${importer}::has" }; # moo/moose lolmoose?

    my $initialize = sub {
       my ($pkg, %args) = @_;
       croak 'first argument must be a package name' if ref $pkg;
       croak 'Must supply a dbh or columns argument' 
            unless $args{dbh} or scalar @{$args{columns}};

       @cols = @{$args{columns}} if @{$args{columns}};
       if ($args{dbh} and !@cols){
            @cols = get_attributes(
                        typeschema => "$pkg"->_get_schema,
                        typename   => "$pkg"->_get_typename,
                        dbh        => $args{dbh}
            );
       }
       return @cols;
    };

    my $from_db = sub {
        my ($to_pkg, $string) = @_;
        my $hashref = pcsv2hash($string, map { $_->{attname}} @cols);
        $hashref = {
             map { $_->{attname} => PGObject::process_type(
                                      $hashref->{$_->{attname}}, 
                                      $_->{atttype},
                                      (eval {$to_pkg->can('_get_registry')} ?
                                            "$to_pkg"->_get_registry        :
                                            'default'))
                  } @cols
        };
        if ($can_has){ # moo/moose
           return "$pkg"->new(%$hashref);
        } else {
           return bless($hashref, $to_pkg);
        }
    };

    my $to_db = sub {
        my ($self) = @_;
        my $hashref = { map { 
                            my $att = $_->{attname};
                            my $val = eval { $self->$att } || $self->{$att};
                            $att => $val;
                      } @cols };
        return { 
            type  => $typename,
            value => hash2pcsv($hashref, map {$_->{attname}} @cols),
         };
    };

    my $register = sub { # easier here than also doing export
        my $self = shift @_;
        croak "Can't pass reference to register \n".
              "Hint: use the class instead of the object" if ref $self;
        my %args = @_;
        my $registry = $args{registry};
        $registry ||= 'default';
        my $types = $args{types};
        croak 'Must supply types as a hashref'
           unless defined $types and @$types;
        for my $type (@$types){
            my $ret =
                PGObject->register_type(registry => $registry, 
                                         pg_type => $type,
                                      perl_class => "$self");
            return $ret unless $ret;
        }
        return 1;
    };
    my $_get_cols = sub {
        return @cols;
    };

    no strict 'refs';
    *{ "${importer}::initialize" } = $initialize;
    *{ "${importer}::register" }   = $register;
    *{ "${importer}::from_db" }    = $from_db;
    *{ "${importer}::to_db" }      = $to_db;
    *{ "${importer}::_get_cols" }  = $_get_cols;
}

=head1 AUTHOR

Chris Travers, C<< <chris.travers at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pgobject-type-composite at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PGObject-Type-Composite>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PGObject::Type::Composite


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PGObject-Type-Composite>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PGObject-Type-Composite>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PGObject-Type-Composite>

=item * Search CPAN

L<http://search.cpan.org/dist/PGObject-Type-Composite/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Chris Travers.

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

* Neither the name of Chris Travers's Organization
nor the names of its contributors may be used to endorse or promote
products derived from this software without specific prior written
permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of PGObject::Type::Composite
