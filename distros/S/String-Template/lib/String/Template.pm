package String::Template;

use strict;
use warnings;
use 5.008001;
use base 'Exporter';
use POSIX;
use Date::Parse;

# ABSTRACT: Fills in string templates from hash of fields
our $VERSION = '0.19'; # VERSION


our @EXPORT = qw(expand_string missing_values expand_stringi);
our @EXPORT_OK = qw(expand_hash);

my %special =
(
    '%' => sub { sprintf("%$_[0]", $_[1]) },

    ':' => sub { strftime($_[0], localtime(str2time($_[1]))) },

    '!' => sub { strftime($_[0], gmtime(str2time($_[1]))) },

    '#' => sub { my @args = split(/\s*,\s*/, $_[0]);
                 defined $args[1]
                 ? substr($_[1], $args[0], $args[1])
                 : substr($_[1], $args[0]) }
);

my $specials = join('', keys %special);
my $specialre = qr/^([^$specials]+)([$specials])(.+)$/;

#
# _replace($field, \%fields, $undef_flag)
#
# replace a single "<field> or "<field%sprintf format>"
# or "<field:strftime format>"
#
sub _replace
{
    my ($field, $f, $undef_flag, $i_flag) = @_;

    if ($field =~ $specialre)
    {
        return ($undef_flag ? "<$field>" : '') unless defined $f->{($i_flag ? lc($1) : $1)};
        return $special{$2}($3,$f->{($i_flag ? lc($1) : $1)});
    }

    my $ifield = $i_flag ? lc $field : $field;
    return defined $f->{$ifield} ? $f->{$ifield}
                                : ($undef_flag ? "<$field>" : '');
}


#
# expand_string($string, \%fields, $undef_flag)
# find "<fieldname>"
#
sub expand_string
{
    my ($string, $fields, $undef_flag) = @_;

    $string =~ s/<([^>]+)>/_replace($1, $fields, $undef_flag)/ge;

    return $string;
}


sub expand_stringi
{
    my ($string, $fields, $undef_flag) = @_;
    my %ifields = map { lc $_ => $fields->{$_} } keys %$fields;

    $string =~ s/<([^>]+)>/_replace($1, \%ifields, $undef_flag, 1)/gie;

    return $string;
}


sub missing_values
{
    my ($string, $fields, $dont_allow_undefs) = @_;
    my @missing;

    while ($string =~ /<([^>$specials]+)(?:[$specials][^>]+)?>/g) {
        next if exists($fields->{$1}) && (!$dont_allow_undefs || defined($fields->{$1}));
        push @missing, $1;
    }
    return unless @missing;
    return @missing;
}


sub expand_hash
{
    my ($hash, $maxdepth) = @_;

    $maxdepth ||= 10;

    my $changeflag = 1;
    my $missing = 1;

    while ($changeflag)
    {    
        $changeflag = 0;
        $missing = 0;
        foreach my $key (sort keys %$hash)
        {
            my $newstr = expand_string($hash->{$key}, $hash, 1);
            
            if ($newstr ne $hash->{$key})
            {
                $hash->{$key} = $newstr;
                $changeflag = 1;
            }
            $missing++ if $newstr =~ /<[^>]+>/;
        }
        last unless --$maxdepth;
    }
    return $missing ? undef : 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

String::Template - Fills in string templates from hash of fields

=head1 VERSION

version 0.19

=head1 SYNOPSIS

 use String::Template;
 
 my %fields = ( num => 2, str => 'this', date => 'Feb 27, 2008' );
 
 my $template = "...<num%04d>...<str>...<date:%Y/%m/%d>...\n";
 
 print expand_string($template, \%fields);
 #prints: "...0002...this...2008/02/27..."

=head1 DESCRIPTION

Generate strings based on a template.

=head1 FUNCTIONS

=head2 expand_string

 my $str = expand_string($template, \%fields, $undef_flag);

Fills in a simple template with values from a hash, replacing tokens
like "<fieldname>" with the value from the hash $fields->{fieldname}.

Some special characters can be used to impose formatting on the
fields:

 % - treat like a sprintf() format
     e.g.  <int%02d>

 : - treat like a L<POSIX::strftime()> format
     e.g. <date:%Y-%m-%d>

 ! - Just like ':', but with gmtime instead of localtime
     e.g. <gmdate!%Y-%m-%d %H:%M>

 # - treat like args to substr()
     e.g. <str#0,2> or <str#4>

For the ':' strftime formats, the field is parsed by L<Date::Parse>,
so it can handle any format that can handle.

Handling of undefined fields can be controlled with $undef_flag.  If
it is false (default), undefined fields are simply replace with an
empty string.  If set to true, the field is kept verbatim.  This can
be useful for multiple expansion passes.

=head2 expand_stringi

 my $str = expand_stringi($template, \%fields, $undef_flag);

expand_stringi works just like expand_string, except that tokens
and hash keys are treated case insensitively.

=head2 missing_values

 my @missing = missing_values($template, \%fields, $dont_allow_undefs);

Checks to see if the template variables in a string template exist
in a hash.  Set $dont_allow_undefs to 1 to also check to see if the
values for all such keys are defined.

Returns a list of missing keys or an empty list if no keys were missing.

=head2 expand_hash

 my $status = expand_hash($hash[, $maxdepth]);

Expand a hash of templates/values.  This function will repeatedly
replace templates in the values of the hash with the values of the
hash they reference, until either all "<>" templates are gone, or
it has iterated $maxdepth times (default 10).

Returns undef if there are unexpanded templates left, otherwise true.

=head1 SEE ALSO

L<String::Format> performs a similar function, with a different
syntax.

=head1 AUTHOR

Original author: Brian Duggan

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Curt Tilmes

Jeremy Mates (thirg, JMATES)

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Brian Duggan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
