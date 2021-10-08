#
# Module Parse::Yapphp::Output
#
# Copyright © 1998, 1999, 2000, 2001, Francois Desarmenien.
# Copyright © 2017 William N. Braswell, Jr.
# (see the pod text in Parse::Yapphp module for use and distribution rights)
#
package Parse::Yapphp::Output;
@ISA=qw ( Parse::Yapphp::Lalr );

require 5.004;

use Parse::Yapphp::Lalr;
use Parse::Yapphp::Driver;

use strict;

use Carp;

sub _CopyDriver {
	my ($srcfile) = $Parse::Yapphp::Driver::FILENAME;

	$srcfile =~ s/[.]pm$/.php/;

	open my $fp, '<', $srcfile or die "BUG: could not open $srcfile";
	my $source = do {
		local $/ = undef;
		<$fp>;
	};
	close $fp;

	($source) = split /^__halt_compiler[(][)]/m, $source;

	return $source;
}

sub _CopyLexer {
	my ($srcfile) = $Parse::Yapphp::Driver::FILENAME;

	$srcfile =~ s/Driver[.]pm$/LexerInterface.php/;

	open my $fp, '<', $srcfile or die "BUG: could not open $srcfile";
	my $source = do {
		local $/ = undef;
		<$fp>;
	};
	close $fp;

	($source) = split /^__halt_compiler[(][)]/m, $source;

	return $source;
}

sub Output {
    my($self)=shift;

    $self->Options(@_);

    my($package)=$self->Option('classname');
    my($head,$states,$rules,$tail,$driver,$lexer);
	my($namespace)=$self->Option('namespace');
    my($version)=$Parse::Yapphp::Driver::VERSION;
    my($driverclass);
    my($text)=$self->Option('template') ||<<'EOT';
<?php
/*******************************************************************
*
*    This file was generated using Parse::Yapphp version <<$version>>.
*
*        Don't edit this file, use source file instead.
*
*             ANY CHANGES MADE HERE WILL BE LOST !
*
*******************************************************************/
<<$namespace>><<$head>>/**
 * "<<$package>>" parser class
 */
class <<$package>> extends <<$driverclass>>
{
    /**
     * @return array
     */
    protected function getRules(): array
    {
    	return <<$rules>>;
    }

    /**
     * @return array
     */
    protected function getStates(): array
    {
    	return <<$states>>;
    }
<<$tail>>
}
EOT

    if (length $namespace) {
        $namespace = "namespace $namespace;\n\n";
    }

    $driverclass = "${package}Driver";

	$head= $self->Head();
	$head .= "\n" if length $head;
	$rules=$self->RulesTable();
	$states=$self->DfaTable();
	$tail= $self->Tail();

	$driver = _CopyDriver();
	$lexer = _CopyLexer();

	$text =~ s/<<(\$[a-z_][a-z_\d]*)>>/$1/igee;
	$lexer =~ s{/[*]<<(\$[a-z_][a-z_\d]*)>>[*]/}{$1}igee;
	$lexer =~ s/<<(\$[a-z_][a-z_\d]*)>>/$1/igee;
	$driver =~ s{/[*]<<(\$[a-z_][a-z_\d]*)>>[*]/}{$1}igee;
    $driver =~ s{^abstract class Driver\b}{abstract class $driverclass}m;

	return ($text, $driver, $lexer);
}

1;
