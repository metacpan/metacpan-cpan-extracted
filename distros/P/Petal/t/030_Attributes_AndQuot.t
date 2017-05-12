#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;


$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::BASE_DIR = './t/data';

my $template;
my $string;


#####

=cut

{
    $Petal::OUTPUT = "XML";
    $template = new Petal ('attributes_andquot.xml');
    
    $string = ${$template->_canonicalize()};
    unlike($string, '/""/');
}


{
    $Petal::OUTPUT = "XHTML";
    $template = new Petal ('attributes_andquot.xml');
    
    $string = ${$template->_canonicalize()};
    unlike($string, '/""/');
}

=cut

{
    $Petal::OUTPUT = "XML";
    $template = new Petal ('inline_vars.xml');
    $string = ${$template->_canonicalize()};
    
    like($string, '/&quot;/');
    
    like($string, '/\<\?/');
    
    like($string, '/\?\>/');
}

exit;

{
    $Petal::OUTPUT = "XHTML";
    $template = new Petal ('inline_vars.xml');
    $string = ${$template->_canonicalize()};

    like($string, '/&quot;/');
    
    like($string, '/<\?/');
    
    like($string, '/\?>/');
}


JUMP:
{
    $Petal::OUTPUT = "XML";
    $template = new Petal ('manipulate.html');
    
    $string = $template->process (
	configuration => { get_identity_field_name => 'id' }
       );

    like($string, '/petal:attributes="value entry\/id;"/');
    
    like($string, '/type="hidden"/');
    
    like($string, '/name="id"/');
}


1;


__END__
