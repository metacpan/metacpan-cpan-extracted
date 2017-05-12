use warnings;
use strict;

use Module::Build;


my $prompt = 'Would you like to enable network tests?';
my $prompt_components = 
qq| If you would like to test the jabberd14 and jabberd20 component connection \n|.
qq| facilities, you will need to have already configured both servers to accept \n|.
qq| connections. If this sounds like a hassle please answer 'N' to the \n|.
qq| following question. \n\nDo you want to enable tests for jabberd14 and \n|.
qq| jabberd20 component connections?|;

my $j14 = qq|### JABBERD14 ###\n|;
my $j20 = qq|### JABBERD20 ###\n|;

my @comps = ($j14, $j20);

my $prompt_ip = 'Please enter the ip address of the server.';
my $prompt_port = 'Please enter the listening port on the server.';
my $prompt_hostname = 'Please enter the hostname the component will represent.';
my $prompt_username = qq|Please enter the username the component will represent.|;
my $prompt_secret = 'Please enter the secret that will be used to auth.';
my $ret;

if (grep /^--default$/, @ARGV) {
	
	print $prompt, " [n] n\n\n";

} else {

	$ret = Module::Build->prompt($prompt, 'n');
}

if($ret =~ /^y/i)
{	
	open(my $file, '>', 'run_network_tests');
	$ret = Module::Build->prompt($prompt_components, 'n');
	
    if($ret =~ /^y/i)
    {
        print "\n" . qq|### JABBERD14 ###\n|;
        print $file qq|### JABBERD14 ###\n|; 
        print $file 'IP=' . Module::Build->prompt($prompt_ip, '127.0.0.1') . "\n";
        print $file 'PORT=' . Module::Build->prompt($prompt_port, '5348') . "\n";
        print $file 'HOST=' . Module::Build->prompt($prompt_hostname, 'component.localhost') . "\n";
        print $file 'SECRET=' . Module::Build->prompt($prompt_secret, 'secret') . "\n";

        print "\n" . qq|### JABBERD20 ###\n|;
        print $file qq|### JABBERD20 ###\n|; 
        print $file 'IP=' . Module::Build->prompt($prompt_ip, '127.0.0.1') . "\n";
        print $file 'PORT=' . Module::Build->prompt($prompt_port, '5347') . "\n";
        print $file 'HOST=' . Module::Build->prompt($prompt_hostname, 'component.localhost') . "\n";
        print $file 'USER=' . Module::Build->prompt($prompt_username, 'jabberd') . "\n";
        print $file 'SECRET=' . Module::Build->prompt($prompt_secret, 'secret') . "\n";
    }
	close($file);

} else {

	unlink 'run_network_tests' if -e 'run_network_tests';
}


Module::Build->new
(
	'module_name' => 'POE::Component::Jabber',
	'license' => 'gpl',
	'create_makefile_pl' => 'passthrough',
	'create_readme' => 1,
	'requires' =>
	{
		'perl'	=>	'5.10.0',
		'POE'	=>	'1.003',
		'Digest::SHA1' => '2.11',
		'Authen::SASL' => '2.12',
		'MIME::Base64' => '3.07_01',
		'POE::Filter::XML' => '0.35',
        'POE::Component::SSLify' => '0.15',
        'POE::Component::PubSub' => '0.05',

	}
)->create_build_script();
