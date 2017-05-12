#!/usr/bin/perl
use strict;
use warnings;
use Test::More 'no_plan';
use lib qw (lib ../lib);
use Petal::Mail;

my $string;
my $formatter = new Petal::Mail (
    base_dir  => [ './t/data', './data' ],
    file      => 'en.xml'
);

$string = $formatter->process();
like ($string, qr /Content-Disposition: inline/);
like ($string, qr /Content-Transfer-Encoding: 8bit/);
like ($string, qr /Content-Language: en/);
like ($string, qr /MIME-Version: 1.0/);
like ($string, qr /Subject: Please help me with important transaction/);
like ($string, qr /User-Agent: MKDoc::Mail 0.1/);
like ($string, qr /Precedence: bulk/);
like ($string, qr /Organization: Rather Messy/);
like ($string, qr /CPAN Account/);
like ($string, qr /    You give me your CPAN account username and password/);


$formatter = new Petal::Mail (
    base_dir  => [ './t/data', './data' ],
    file      => 'en.xml',
    input     => 'HTML',
);

$string = $formatter->process();
like ($string, qr /Content-Disposition: inline/);
like ($string, qr /Content-Transfer-Encoding: 8bit/);
like ($string, qr /Content-Language: en/);
like ($string, qr /MIME-Version: 1.0/);
like ($string, qr /Subject: Please help me with important transaction/);
like ($string, qr /User-Agent: MKDoc::Mail 0.1/);
like ($string, qr /Precedence: bulk/);
like ($string, qr /Organization: Rather Messy/);
like ($string, qr /CPAN Account/);
like ($string, qr /    You give me your CPAN account username and password/);


$formatter = new Petal::Mail (
    base_dir  => [ './t/data', './data' ],
    file      => 'en.xml',
    input     => 'XHTML',
);

$string = $formatter->process();
like ($string, qr /Content-Disposition: inline/);
like ($string, qr /Content-Transfer-Encoding: 8bit/);
like ($string, qr /Content-Language: en/);
like ($string, qr /MIME-Version: 1.0/);
like ($string, qr /Subject: Please help me with important transaction/);
like ($string, qr /User-Agent: MKDoc::Mail 0.1/);
like ($string, qr /Precedence: bulk/);
like ($string, qr /Organization: Rather Messy/);
like ($string, qr /CPAN Account/);
like ($string, qr /    You give me your CPAN account username and password/);


$formatter = new Petal::Mail (
    base_dir  => [ './t/data', './data' ],
    file      => 'en.xml',
    output    => 'HTML',
);

$string = $formatter->process();
like ($string, qr /Content-Disposition: inline/);
like ($string, qr /Content-Transfer-Encoding: 8bit/);
like ($string, qr /Content-Language: en/);
like ($string, qr /MIME-Version: 1.0/);
like ($string, qr /Subject: Please help me with important transaction/);
like ($string, qr /User-Agent: MKDoc::Mail 0.1/);
like ($string, qr /Precedence: bulk/);
like ($string, qr /Organization: Rather Messy/);
like ($string, qr /CPAN Account/);
like ($string, qr /    You give me your CPAN account username and password/);


$formatter = new Petal::Mail (
    base_dir  => [ './t/data', './data' ],
    file      => 'en.xml',
    output    => 'XHTML',
);

$string = $formatter->process();
like ($string, qr /Content-Disposition: inline/);
like ($string, qr /Content-Transfer-Encoding: 8bit/);
like ($string, qr /Content-Language: en/);
like ($string, qr /MIME-Version: 1.0/);
like ($string, qr /Subject: Please help me with important transaction/);
like ($string, qr /User-Agent: MKDoc::Mail 0.1/);
like ($string, qr /Precedence: bulk/);
like ($string, qr /Organization: Rather Messy/);
like ($string, qr /CPAN Account/);
like ($string, qr /    You give me your CPAN account username and password/);


1;


__END__
