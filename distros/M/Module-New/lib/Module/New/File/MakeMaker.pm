package Module::New::File::MakeMaker;

use strict;
use warnings;
use Module::New::File;

file 'Makefile.PL' => content { return <<'EOT';
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %params = (
    NAME          => '<%= $c->module %>',
    AUTHOR        => '<%= $c->config('author') %> <<%= $c->config('email') %>>',
    VERSION_FROM  => '<%= $c->mainfile %>',
    ABSTRACT_FROM => '<%= $c->mainfile %>',
    LICENSE       => '<%= $c->config('license') || 'perl' %>',
    PREREQ_PM     => {
    },
    BUILD_REQUIRES => {
        'Test::More'          => '0.88', # done_testing
        'Test::UseAllModules' => '0.10',
    },
    META_MERGE => {
        resources => {
            repository => '<%= $c->repository %>',
        },
    },
);

my $eumm = eval $ExtUtils::MakeMaker::VERSION;
delete $params{LICENSE}          if $eumm < 6.31;
delete $params{MIN_PERL_VERSION} if $eumm < 6.48;
delete $params{META_MERGE}       if $eumm < 6.46;
delete $params{META_ADD}         if $eumm < 6.46;

if ($eumm < 6.52 && $params{CONFIGURE_REQUIRES}) {
    $params{PREREQ_PM} = {
        %{ $params{PREREQ_PM}          || {} },
        %{ $params{CONFIGURE_REQUIRES} },
    };
    delete $params{CONFIGURE_REQUIRES};
}
if ($eumm < 6.5503 && $params{BUILD_REQUIRES}) {
    $params{PREREQ_PM} = {
        %{ $params{PREREQ_PM}      || {} },
        %{ $params{BUILD_REQUIRES} },
    };
    delete $params{BUILD_REQUIRES};
}

WriteMakefile(%params);
EOT
};

1;

__END__

=head1 NAME

Module::New::File::MakeMaker

=head1 DESCRIPTION

a template for C<Makefile.PL> (with L<ExtUtils::MakeMaker>).

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
