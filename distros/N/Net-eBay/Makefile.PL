use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
              NAME                => 'Net::eBay',
              AUTHOR              => 'Igor Chudov <ichudov@algebra.com>',
              VERSION_FROM        => 'lib/Net/eBay.pm',
              ABSTRACT            => 'XML based communication with eBay API',
              PL_FILES            => {},
              EXE_FILES           => [ 'ebay-official-time.pl', 'ebay-validate-test-user.pl',
                                       'ebay-get-categories.pl', 'ebay-add-item.pl', 'ebay-search.pl',
                                       'ebay-revise-item.pl', 'ebay-get-item.pl'
                                     ],
              PREREQ_PM => {
                            'Test::More' => 0,
                            'Text::Format' => 0,
                            'XML::Simple' => 0,
                            'XML::Dumper' => 0,
                            'Data::Dumper' => 0,
                            'LWP::UserAgent' => 0,
                            'HTTP::Request::Common' => 0,
                            'HTTP::Status' => 0,
                            'HTTP::Date' => 0,
                            'Net::SSLeay' => 0,
                            'Crypt::SSLeay' => 0,
                            'HTML::TreeBuilder' => 0,
                            'HTML::PrettyPrinter' => 0,
                            'HTML::FormatText' => 0,
                            'DateTime::Precise' => 0,
                           },
              dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
              clean               => { FILES => 'Net-eBay-*' },
);
