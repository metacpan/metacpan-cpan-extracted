package Number::ZipCode::JP;

use strict;
use warnings;
use 5.008_001;
use Carp;
use UNIVERSAL::require;

our $VERSION = '0.20210930';
our %ZIP_TABLE = ();

sub import {
    my $self = shift;
    %ZIP_TABLE = ();
    if (@_) {
        my @packages = ();
        for my $subclass (@_) {
            push @packages, 
                sprintf('%s::Table::%s', __PACKAGE__, ucfirst(lc($subclass)));
        }
        %ZIP_TABLE = _merge_table(@packages);
    }
    else {
        require Number::ZipCode::JP::Table;
        import  Number::ZipCode::JP::Table;
    }
    return $self;
}

sub _merge_table {
    my %table = ();
    for my $pkg (@_) {
        $pkg->require or croak $@;
        {
            no strict 'refs';
            while (my($k, $v) = each %{"$pkg\::ZIP_TABLE"}) {
                $table{$k} ||= [];
                push @{$table{$k}}, $v;
            }
        }
    }
    return %table;
}

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    $self->set_number(@_) if @_;
    return $self;
}

sub set_number {
    my $self   = shift;
    my $number = shift;
    if (ref($number) eq 'ARRAY') {
        $self->_prefix = shift @$number;
        $self->_suffix = shift @$number;
    }
    elsif (defined $_[0]) {
        $self->_prefix = $number;
        $self->_suffix = $_[0];
    }
    elsif ($number =~ /^(\d{3})(?:\D)?(\d{4})$/) {
        my $pref = $1;
        my $suff = $2;
        $self->_prefix = $pref;
        $self->_suffix = $suff;
    }
    else {
        carp "The number is invalid zip-code.";
        $self->_prefix = ();
        $self->_suffix = ();
    }
    return $self;
}

sub is_valid_number {
    my $self = shift;
    my $pref = $self->_prefix;
    my $suff = $self->_suffix;
    unless ($pref || $suff) {
        carp "Any number was not set";
        return;
    }
    return unless $pref =~ /^\d{3}$/ && $suff =~ /^\d{4}$/;
    my $re_ref = $ZIP_TABLE{$pref};
    return unless defined $re_ref && ref($re_ref) eq 'ARRAY';
    my $matched;
    for my $re (@$re_ref) {
        if ($suff =~ /^$re$/) {
            $matched = 1;
            last;
        }
    }
    return $matched;
}

sub _prefix : lvalue { shift->{_prefix} }
sub _suffix : lvalue { shift->{_suffix} }

1;
__END__

=head1 NAME

Number::ZipCode::JP - Validate Japanese zip-codes

=head1 SYNOPSIS

 use Number::ZipCode::JP;
 
 my $zip = Number::ZipCode::JP->new('100', '0001');
 print "This is valid!!\n" if $zip->is_valid_number;
 
 $zip->set_number('100-0001');
 print "This is valid!!\n" if $zip->is_valid_number;
 
 $zip->import(qw(area));
 $zip->set_number('1000001');
 print "This is valid!!\n" if $zip->is_valid_number;

=head1 DESCRIPTION

Number::ZipCode::JP is a simple module to validate Japanese zip-code formats.
The Japanese zip-codes are regulated by Japan Post Holdings Co., Ltd.
You can validate what a target zip-code is valid from this regulation
point of view.

There are some categories for type of construct in Japan. This module
is able to be used narrowed down to the type of construct.

This module validates what a zip-code agrees on the regulation.

=head1 METHODS

=head2 new

This method constructs the Number::ZipCode::JP instance. you can put
some argument of a zip-code to it.
It needs a two stuff for validation, area prefix and following
(means an area suffix or a company-specific suffix).

If you put only one argument, this module will separate it by
4 digits and 3 digits. And you can put a non-numeric character between them.

=head2 import

It exists to select what categories is used for validation. You should
pass some specified categories to this method.

Categories list is as follows:

 Area    ... area-specific zip-codes
 Company ... company-specific (includes P.O.Box) zip-codes

The category's names are B<ignored case>. Actually, the import method
calls others C<Number::ZipCode::JP::Table::>I<Category> module and
import this. The default importing table, C<Number::ZipCode::JP::Table>
module is including all the categories table.

For importing, you can import by calling this method, and you can
import by B<calling this module> with some arguments.

 Example:
  # by calling import method
  use Number::ZipCode::JP; # import all the categories (default)
  my $zip = Number::ZipCode::JP->new->import(qw(company));
 
  # by calling this module
  use Number::ZipCode::JP qw(company);
  my $zip = Number::ZipCode::JP->new; # same as above

=head2 set_number

Set/change the target zip-code. The syntax of arguments for this
method is same as C<new()> method (see above).

=head2 is_valid_number

This method validates what the already set number is valid on your
specified categories. It returns true if the number is valid, and
returns false if the number is invalid.

=head1 EXAMPLE

 use Number::ZipCode::JP qw(area);
 
 my $zip = Number::ZipCode::JP->new;
 open FH, 'customer.list' or die "$!";
 while (<FH>) {
     chomp;
     unless ($zip->set_number($_)->is_valid_number) {
         print "$_ is invalid number\n"
     }
 }
 close FH;

=head1 AUTHOR

Koichi Taniguchi (a.k.a. nipotan) E<lt>taniguchi@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Number::ZipCode::JP::Table>

=cut
