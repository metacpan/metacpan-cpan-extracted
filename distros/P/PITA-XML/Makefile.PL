use inc::Module::Install::DSL 1.06;

all_from      lib/PITA/XML.pm
requires      Carp                    0
requires      Config::Tiny            2.02
requires      IO::Handle              0
requires      IO::Seekable            0
requires      IO::File                0
requires      IO::String              1.06
requires      File::Which             1.07
requires      File::ShareDir          1.00
requires      Params::Util            1.00
requires      Class::Inspector        1.11
requires      Class::Autouse          1.23
requires      Data::Digest            0.02
requires      XML::SAX::Writer        0.52
requires      XML::SAX::ParserFactory 1.01
# requires      XML::Validator::Schema  1.08
test_requires File::Spec              0.80
test_requires Test::More              0.47
test_requires Test::XML               0.08
test_requires Data::UUID              1.149
install_share
