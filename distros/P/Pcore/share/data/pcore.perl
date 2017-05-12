{   par => {

        # common modules, that will be added to the each PAR
        mod => [

            # eg.:
            # 'bytes_heavy.pl',
            # 'HTTP/Date.pm',
        ],

        # common modules to ignore
        mod_ignore => [    #
            'Method/Generate/Accessor__WITH__Method/Generate/Accessor/Role/TypeTiny.pm',
            'Method/Generate/Accessor__WITH__Method/Generate/Accessor/Role/TypeTiny__WITH__Method/Generate/Accessor/Role/TypeTiny.pm',
        ],

        # architecture dependent settings
        arch => {
            'MSWin32-x86-multi-thread-64int' => {

                # common arch. dependent modules, same as "mod", but arch. dependent
                mod => [],

                # common arch. dependent shared libs names, used by modules
                mod_shlib => {
                    'B/Hooks/OP/Check.pm'      => ['auto/B/Hooks/OP/Check/Check.xs.dll'],
                    'BerkeleyDB.pm'            => ['libdb-6.2_.dll'],
                    'Filter/Crypto/Decrypt.pm' => [ 'libeay32_.dll', 'zlib1_.dll' ],
                    'Net/LibIDN.pm'            => [ 'libidn-11_.dll', 'libiconv-2_.dll' ],
                    'Net/SSLeay.pm'            => [ 'ssleay32_.dll', 'libeay32_.dll', 'zlib1_.dll' ],
                    'Pcore/RPC/Proc.pm'        => [$^X],
                    'XML/Hash/XS.pm'           => [ 'libxml2-2_.dll', 'libiconv-2_.dll', 'zlib1_.dll', 'liblzma-5_.dll' ],
                    'XML/LibXML.pm'            => [ 'libxml2-2_.dll', 'libiconv-2_.dll', 'zlib1_.dll', 'liblzma-5_.dll' ],
                },
            },
            'MSWin32-x64-multi-thread' => {

                # common default arch. dependent modules, same as "mod", but arch. dependent
                mod => [],

                # common arch. dependent shared libs names, used by modules
                mod_shlib => {
                    'B/Hooks/OP/Check.pm'      => ['auto/B/Hooks/OP/Check/Check.xs.dll'],
                    'BerkeleyDB.pm'            => ['libdb-6.2__.dll'],
                    'Filter/Crypto/Decrypt.pm' => [ 'libeay32__.dll', 'zlib1__.dll' ],
                    'Net/LibIDN.pm'            => [ 'libidn-11__.dll', 'libiconv-2__.dll' ],
                    'Net/SSLeay.pm'            => [ 'ssleay32__.dll', 'libeay32__.dll', 'zlib1__.dll' ],
                    'Pcore/RPC/Proc.pm'        => [$^X],
                    'XML/Hash/XS.pm'           => [ 'libxml2-2__.dll', 'libiconv-2__.dll', 'zlib1__.dll', 'liblzma-5__.dll' ],
                    'XML/LibXML.pm'            => [ 'libxml2-2__.dll', 'libiconv-2__.dll', 'zlib1__.dll', 'liblzma-5__.dll' ],
                },
            },
        },
    },
};
