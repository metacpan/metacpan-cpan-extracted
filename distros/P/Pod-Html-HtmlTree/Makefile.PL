use ExtUtils::MakeMaker;
                                                                                                               WriteMakefile(
		NAME            => 'lib/Pod/Html/HtmlTree',
		VERSION_FROM    => 'lib/Pod/Html/HtmlTree.pm',
		PREREQ_PM       => { 	Pod::Html      => 0 ,
					File::Path     => 0 ,
					File::Find     => 0 ,
					File::Spec     => 0 ,
					File::Basename => 0 ,
					List::Util     => 0 ,
					},
		AUTHOR		=> 'Tomohiro Teranishi <tomohiro.teranishi+cpan@gmail.com>',
	);

