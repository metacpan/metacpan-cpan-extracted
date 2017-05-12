use inc::Module::Install;

license 'mit';

all_from 'lib/Phash/FFI.pm';

repository 'git://github.com/gugod/Phash-FFI.git';

requires
    'FFI::Platypus' => '0.12',
    'FFI::CheckLib' => '0.03';

tests 't/*.t';

makemaker_args(
    dist => {
        COMPRESS => "zopfli -i50",
    }
);

WriteAll;
