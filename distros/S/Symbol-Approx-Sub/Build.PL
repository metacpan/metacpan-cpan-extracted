use Module::Build;

my $build = Module::Build->new(
	module_name        => 'Symbol::Approx::Sub',
        license            => 'perl',
        create_makefile_pl => 'traditional',
        requires           => {
                perl                => '5.006',
		Devel::Symdump      => 0,
		Carp                => 0,
		Module::Load        => 0,
		Exception::Class    => 0,
	},
        recommends         => {
		String::Approx      => 0,
		Text::Metaphone     => 0,
		Text::Soundex       => 0,
	},
        configure_requires => {
                Module::Build       => 0,
        },
        build_requires     => {
		Test::More          => 0,
		Test::Exception     => 0,
		String::Approx      => 0,
		Text::Metaphone     => 0,
		Text::Soundex       => 0,
	},
        build_recommends   => {
		Test::Pod           => 0,
		Test::Pod::Coverage => 0,
	},
        meta_merge => {
               'meta-spec' => { version => 2 },
                resources  => {
                        repository => {
                                type => 'git',
                                url  => 'https://github.com/davorg/symbol-approx-sub.git',
                                web  => 'https://github.com/davorg/symbol-approx-sub',
                        },
                },
        },
);

$build->create_build_script;
