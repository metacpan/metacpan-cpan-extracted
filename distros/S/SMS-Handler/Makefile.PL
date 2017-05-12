
# $Id: Makefile.PL,v 1.13 2003/01/14 20:32:34 lem Exp $

use ExtUtils::MakeMaker;

if ($] <= 5.006)
{
    warn <<EOT;

Your version of Perl is unstable when using Params::Validate. Please
consider upgrading. Perl may dump core ocassionaly when fed wrong
arguments to this module.

EOT
    ;
}

WriteMakefile(
    'NAME'		=> 'SMS::Handler',
    'VERSION_FROM'	=> 'lib/SMS/Handler.pm', # finds $VERSION
    'PREREQ_PM'		=> 
	      {
		  'Params::Validate'	=> 0, # To properly validate args
		  'Test::More'		=> 0, # For laziness' sake
		  'Digest::MD5'		=> 0, # Used for encription
				# Requires serialization
		  'Net::SMPP'		=> 1.04,
		  'Storable'		=> 0,
		  'Net::POP3'		=> 0, # For ::Email
		  'Net::SMTP'		=> 0, # For ::Email
		  'Mail::Audit'		=> 0, # For ::Email
		  'Mail::Address'	=> 0, # For ::Email
		  'Text::Abbrev'	=> 0, # For ::Email
		  'MIME::WordDecoder'	=> 0, # For ::Email
		  'MIME::Parser'	=> 0, # For ::Email
		  'HTML::Parser'	=> 0, # For ::Email
		  'Date::Parse'		=> 0, # For ::Email
		  'Unicode::Map8'	=> 0, # For ::Email
	      }, # e.g., Module::Name => 1.1
	      ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       (ABSTRACT_FROM	=> 'lib/SMS/Handler.pm',
		AUTHOR     	=> 'Luis E. Muñoz <lem@cantv.net>') : ()),
);
