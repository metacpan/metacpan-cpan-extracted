package PHP::Include;

use strict;
use warnings;
use Filter::Simple;
use Carp qw( croak );

our $VERSION = '0.37';
our $DEBUG = 0;
our $QUALIFIER = "my";

FILTER {

    ## read in any options and turn on diagnostics if asked 

    my ( $class, %options ) = map { lc($_) } @_; 
    $DEBUG = 1 if $options{debug};
    $QUALIFIER = "our" if $options{our};

    ## include_php_vars() macro
    s/
	(.*)			# any amt of leading text
	include_php_vars	# function call
	\s*			# optional whitespace
	\(			# opening parens	
	\s*			# optional whitespace
	(["'])			# opening single or double quote
	(.+)			# a string
	\2			# closing single or double quote
	\s*			# optional whitespace
	\)			# closing paren
	.*;			# rest of the line
    /
	$1.
	read_file( 'PHP::Include::Vars', $3);
    /gex;



};

## read a file and return it's contents with the appropriate
## filter around it

sub read_file {
    my ($filter,$file) = @_;
    print STDERR qq(OPENING PHP FILE "$file" FOR FILTER $filter\n\n) if $DEBUG;
    open( IN, $file ) || croak( "$file doesn't exist!" );
    my $php =  join( '', <IN> );
    # strip comments (sorry if you have # in strings)
    ## $php =~ s!^\s*(?:#|//).*\n!!gm; # full line comments, delete line
    ## $php =~ s!(?:#|//).*\n!\n!g;    # others, keep new line
    print STDERR "ORIGINAL PHP:\n\n", $php if $DEBUG;
    close( IN );
    return( "use $filter '$QUALIFIER';\n" . $php . "no $filter;\n" );
}

1;

=encoding UTF-8

=head1 NAME

PHP::Include - Include PHP files in Perl 

=head1 SYNOPSIS

    use PHP::Include;
    include_php_vars( 'file.php' );

=head1 DESCRIPTION

PHP::Include builds on the shoulders of Filter::Simple and Parse::RecDescent to
provide a Perl utility for including very simple PHP Files from a Perl program.

When working with Perl and PHP it is often convenient to be able to share
configuration data between programs written in both languages.  One solution to
this would be to use a language independent configuration file (did I hear
someone say XML?). Another solution is to use Perl's flexibility to read PHP
and rewrite it as Perl. PHP::Include does the latter with the help of
Filter::Simple and Parse::RecDescent to rewrite very simple PHP as Perl.

Filter::Simple is used to enable macros (at the moment only one) which 
cause PHP to be interpolated into your Perl source code, which is then parsed
using a Parse::RecDescent grammar to generate the appropriate Perl.

PHP::Include was designed to allow the more adventurous to add grammars that 
extend the complexity of PHP that may be included.

=head1 EXPORTS

=head2 include_php_vars( file )

This function is actually a macro that allows you to include PHP variable
declarations in much the same way that you might C<require> a file of Perl 
code. For example, given a file of PHP variable declarations:

    <?php

    define( "PORT", 80 );
    $robot = 'Book Agent';
    $hosts = Array( 
	'www.amazon.com'	=> 'Amazon',
	'www.bn.com'		=> 'Barnes and Noble',
	'www.bookpool.com'	=> 'BookPool'
    );
    $times = Array( 10,12,14,16,18 );

    ?>

You can use this from your Perl program like so:

    use PHP::Include;
    include_php_vars( 'file.php' );

Behind the scenes the PHP is rewritten as this Perl:

    use constant PORT => 80;
    my $robot = 'Book Agent';
    my %hosts = (
	'www.amazon.com'	=> 'Amazon',
	'www.bn.com'		=> 'Barnes & Noble',
	'www.bookpool.com'	=> 'BookPool'
    );
    my @times = ( 10,12,14,16,18 );

Notice that the enclosing E<lt>php? and ?E<gt> are removed, all
variables are lexically scoped with 'my' and that the $ sigils are
changed as appropriate to (@ and %). In addition PHP constant
definitions are translated into Perl constants.

=head1 MY vs OUR

Variables are usually defined using 'my' qualifier. A 'our' qualifier
can be forced using:

   use PHP::Include ( our => 1 );

=head1 DIAGNOSTICS

If you would like to see diagnostic information on STDERR you will
need to use this module slightly differently:

    use PHP::Include ( DEBUG => 1 );

This will cause the PHP that is read in, and the generated Perl to be printed on
STDERR. It can be handy if you are trying to extend the grammar, or are trying
to figure out what isn't getting parsed properly.

=head1 TODO

=over 4

=item * assigning directly to array elements 

=item * support other PHP code enclosures

=item * store compiled grammar if possible for speed gain

=back

=head1 SEE ALSO

=over 4

=item * PHP::Include::Vars

=item * Filter::Simple

=item * Parse::RecDescent

=back

=head1 AUTHOR

Maintained by Alberto Simões, E<lt>ambs@cpan.orgE<gt>

Ed Summers, E<lt>ehs@pobox.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002-2010 by Ed Summers

Copyright 2011-2013 by Alberto Simões

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
