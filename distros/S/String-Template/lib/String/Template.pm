package String::Template;

use strict;
use warnings;
use 5.008001;
use base 'Exporter';
use POSIX ();
use Date::Parse;

# ABSTRACT: Fills in string templates from hash of fields
our $VERSION = '0.23'; # VERSION


our @EXPORT = qw(expand_string missing_values expand_stringi);
our @EXPORT_OK = qw(expand_hash);
our %EXPORT_TAGS = ( all => [@EXPORT, @EXPORT_OK] );

my %special =
(
    '%' => sub { sprintf("%$_[0]", $_[1]) },

    ':' => sub { POSIX::strftime($_[0], localtime(str2time($_[1]))) },

    '!' => sub { POSIX::strftime($_[0], gmtime(str2time($_[1]))) },

    '#' => sub { my @args = split(/\s*,\s*/, $_[0]);
                 defined $args[1]
                 ? substr($_[1], $args[0], $args[1])
                 : substr($_[1], $args[0]) }
);

my $specials = join('', keys %special);
my $specialre = qr/^([^{$specials]+)([{$specials])(.+)$/;
my $bracketre = qr/^([^$specials]*?)([{$specials])(.*?)(?<!\\)\}(.*)$/;

$special{'{'} = sub {
    my ($field, $replace) = @_;
    $field =~ s/\\\}/}/g;
    my ($pre, $key, $spec, $post) = $field =~ /$bracketre/;
    $pre . $special{$key}($spec, $replace) . $post;
};

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

version 0.23

=head1 SYNOPSIS

 use String::Template;
 
 my %fields = ( num => 2, str => 'this', date => 'Feb 27, 2008' );
 
 my $template = "...<num%04d>...<str>...<date:%Y/%m/%d>...\n";
 
 print expand_string($template, \%fields);
 #prints: "...0002...this...2008/02/27..."

=head1 DESCRIPTION

Generate strings based on a template.

=head2 template language

Replacement tokens are denoted with angle brackets.  That is C<< <fieldname> >>
is replaced by the values in the C<< \%fields >> hash reference provided.

Some special characters can be used after the field name to impose formatting on the
fields:

=over 4

=item C<%>

Treat like a L<sprintf|perlfunc/sprintf> format, example: C<< <int%02d> >>.

=item C<:>

Treat like a L<POSIX/strftime> format, example C<< <date:%Y-%m-%d> >>.

The field is parsed by L<Date::Parse>, so it can handle any format that it
can handle.

=item C<!>

[version 0.05]

Same as C<:>, but with L<gmtime|perlfunc/gmtime> instead of L<localtime|perlfunc/localtime>.

=item C<#>

Treat like args to L<substr|perlfunc/substr>; example C<< <str#0,2> >> or C<< <str#4> >>.

=item C<{> and C<}>

[version 0.20]

The C<{> character is specially special, since it allows fields to
contain additional characters that are not intended for formatting.
This is specially useful for specifying additional content inside a
field that may not exist in the hash, and which should be entirely
replaced with the empty string.

This makes it possible to have templates like this:

 my $template = '<name><nick{ "%s"}><surname{ %s}>';
 
 my $mack = { name => 'Mack', nick    => 'The Knife' };
 my $jack = { name => 'Jack', surname => 'Sheppard'  };
 
 expand_string( $template, $mack ); # Returns 'Mack "The Knife"'
 expand_string( $template, $jack ); # Returns 'Jack Sheppard'

=back

=head1 FUNCTIONS

All functions are exported by default, or by request, except for L</expand_hash>

=head2 expand_string

 my $str = expand_string($template, \%fields);
 my $str = expand_string($template, \%fields, $undef_flag);

Fills in a simple template with values from a hash, replacing tokens
with the value from the hash C<< $fields{fieldname} >>.

Handling of undefined fields can be controlled with C<$undef_flag>.  If
it is false (default), undefined fields are simply replaced with an
empty string.  If set to true, the field is kept verbatim.  This can
be useful for multiple expansion passes.

=head2 expand_stringi

[version 0.08]

 my $str = expand_stringi($template, \%fields);
 my $str = expand_stringi($template, \%fields, $undef_flag);

C<expand_stringi> works just like L</expand_string>, except that tokens
and hash keys are treated case insensitively.

=head2 missing_values

[version 0.06]

 my @missing = missing_values($template, \%fields);
 my @missing = missing_values($template, \%fields, $dont_allow_undefs);

Checks to see if the template variables in a string template exist
in a hash.  Set C<$dont_allow_undefs> to 1 to also check to see if the
values for all such keys are defined.

Returns a list of missing keys or an empty list if no keys were missing.

=head2 expand_hash

[version 0.07]

 my $status = expand_hash($hash);
 my $status = expand_hash($hash, $maxdepth);

Expand a hash of templates/values.  This function will repeatedly
replace templates in the values of the hash with the values of the
hash they reference, until either all C<< <fieldname> >> templates are gone, or
it has iterated C<$maxdepth> times (default 10).

Returns C<undef> if there are unexpanded templates left, otherwise true.

This function must be explicitly exported.

=head1 SEE ALSO

L<String::Format> performs a similar function, with a different
syntax.

=head1 AUTHOR

Original author: Brian Duggan

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Curt Tilmes

Jeremy Mates (thirg, JMATES)

José Joaquín Atria

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Brian Duggan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
