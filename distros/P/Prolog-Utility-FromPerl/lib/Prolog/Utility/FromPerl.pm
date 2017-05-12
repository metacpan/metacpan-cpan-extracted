package Prolog::Utility::FromPerl;

use warnings;
use strict;

use version; 

our $VERSION = qv('1.0.2');

use Regexp::Common qw(balanced);

use base qw(Exporter);

our @EXPORT = qw(printable_prolog chain_terms prolog_term prolog_hash prolog_list);


sub printable_prolog {
 
 my $prolog = shift;

 return $prolog if !defined($prolog);

 if(ref($prolog) eq 'SCALAR') {

    ${$prolog} .= '.' if ${$prolog} !~ /\.$/;
     
 } elsif(ref(\$prolog) eq 'SCALAR') {
    $prolog .= '.' if $prolog !~ /\.$/;
 } 

 return $prolog;

}

sub chain_terms {
  
  my @terms = ();

  if(scalar(@_) == 1 && ref($_[0]) eq 'ARRAY') {

    @terms = @{$_[0]};

  } else {
    
    @terms = @_;

  }

  return printable_prolog( join(',',map { s/\.$//g; $_; } grep { defined($_) } @terms ) );

}

sub prolog_term {

  my @nested = caller(1);

  my $term = shift;

  my $prolog = $term .  '(';

  foreach my $value (@_) {

    if(ref($value)) {

        $prolog .= convert_ref_to_prolog($value);

    } else {

        if(ref(\$value) ne 'SCALAR') {

            $prolog .= convert_ref_to_prolog(\$value);

        } else {

            $prolog .= quote_prolog_value($value) . ',';

        }

    }

  }

  if( scalar(@nested) > 0 ) {

    $prolog =~ s/,$//g;

    return $prolog . ')';

 } else {

    return add_prolog_term_end($prolog);

  }

}


sub add_prolog_term_end {

  my $partial_prolog_string = shift;

  $partial_prolog_string =~ s/,$//g;

  my $PATTERN = $RE{balanced};

  my @parts = ($partial_prolog_string =~ /$PATTERN/g);

  if( scalar(@parts) > 1 ) {

    $partial_prolog_string .= ')';

  } elsif(scalar(@parts) == 1 && length($partial_prolog_string) < length($parts[1])) {

    $partial_prolog_string .= ')';

  } else {

    if($partial_prolog_string =~ /\(/ && $partial_prolog_string !~ /\)/) {

        $partial_prolog_string =~ s/,$//g;

        $partial_prolog_string .= ')';

    }

  }

  return $partial_prolog_string;

}

sub convert_ref_to_prolog {

  my $ref = shift;

  if(ref($ref) eq 'ARRAY') {

    return prolog_list($ref);

  } elsif(ref($ref) eq 'HASH') {

    return prolog_hash($ref);

  } elsif(ref($ref) eq 'SCALAR') {

    return quote_prolog_value(${$ref});

  } else {

    die(ref($ref) . ' unsuppored reference' . "\n");

  }

}

sub prolog_list {

 my @list = ();

 if(ref($_[0])) {

    @list = @{$_[0]};

 } else {

    @list = @_;

 }

 return '[' . join(',',map { if(defined($_)) { quote_prolog_value($_); } else { "'nil'"; } } @list) . ']';

}

sub prolog_hash {

  my %hash;

  if(ref($_[0])) {

        %hash = %{$_[0]};

  } else {

        %hash = @_;

  }

  my $sort = delete $hash{_SORT};

  if(defined($sort) && ref($sort) eq 'ARRAY') {

    return join(',',map { prolog_term($_,$hash{$_}); } grep { exists($hash{$_}) } @$sort);

  } else {

    return join(',',map { prolog_term($_,$hash{$_}); } sort keys %hash);

  }

}

sub quote_prolog_value {
 
  my $value = shift;

  return $value if $value =~ /\(/;

  return $value if $value =~ /^[a-z]+[a-z0-9]+$/;

  return $value if $value =~ /^\d+(\.\d+)?$/;

  return $value if $value eq '[]';

  return "'" . $value . "'";

}


1; # Magic true value required at end of module
__END__

=head1 NAME

Prolog::Utility::FromPerl - utility function to convert perl data structures to prolog terms


=head1 VERSION

This document describes Prolog::Utility::FromPerl version 1.0.2


=head1 SYNOPSIS

    use Prolog::Utility::FromPerl;

    my $h = { foo => 1, bar => [2,3], baz => { a => 123 } };

    my $t = prolog_term('wtf',$h);

    say $t; # wtf(bar(2,3), baz(a(123)), foo(1))  

    my $sort_hash = { abc => 1, xyz => 2, '_SORT' => ['xyz','abc'] };

    my $sorted_term = prolog_term('somefact',$sort_hash);

    say $sorted_term; # somefact(xyz(2),abc(1))

    my $functor=prolog_term('foo',1,2,3,'bar');

    say $functor; # foo(1,2,3,'bar')

    my $chained_term = chain_terms(prolog_term('foo',1),prolog_term('bar',2));

    say $chained_term; # foo(1),bar(2).

    my $type=prolog_term('type','bigserial');

    my $name=prolog_term('name','id');

    my $nullstatus=prolog_term('status','NOT NULL');

    my $column=prolog_term('column',$name,$type,$nullstatus);

    my $tablename=prolog_term('name','deal_reservation');

    my $columnlist = prolog_list($column);

    my $columns = prolog_term('columns',$columnlist);

    my $table=prolog_term('table',$name,$columns);

    say $table;
  
  
=head1 DESCRIPTION

    This module provides utility functions for converting perl data 
    structures to prolog terms.  Its main use case is for generating 
    prolog facts that will be written to a file for consulting by prolog.

=head1 INTERFACE 

=over

=item prolog_term given a name, and a data structure, return a prolog term

=item printable_prolog prepare a prolog term for printing by appending a period at the end of the term.

=item chain_terms given an array or array reference of terms, join them by commas and append a final period to them.

=item prolog_hash given a hash or hash reference, convert each key value pair to a prolog term. The keys will be sorted by the sort function in order to maintain a consistent order due to hash randomization in perl 5.18.  If you provide a key named _SORT with a value that is an array reference containing the other keys in the order you wish them to appear, they will be sorted by this order. The _SORT key itself will not appear in the output.

=item prolog_list given an array or array reference, convert to a prolog list

=back

=head1 DIAGNOSTICS

=over

=item C<< unsupported reference >>

prolog_term can only convert scalar, array, or hash references

=back

=head1 CONFIGURATION AND ENVIRONMENT

Prolog::Utility::FromPerl requires no configuration files or environment variables.

=head1 DEPENDENCIES

    Regex::Common
    Test::More
    version

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-prolog-utility-fromperl@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Tyson Maly  C<< <tvmaly@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Tyson Maly C<< <tvmaly@cpan.org> >>. All rights reserved.

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
