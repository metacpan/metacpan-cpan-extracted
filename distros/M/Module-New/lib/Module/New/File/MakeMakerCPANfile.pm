package Module::New::File::MakeMakerCPANfile;

use strict;
use warnings;
use Module::New::File;

file 'Makefile.PL' => content { return <<'EOT';
use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    NAME          => '<%= $c->module %>',
    AUTHOR        => '<%= $c->config('author') %> <<%= $c->config('email') %>>',
    VERSION_FROM  => '<%= $c->mainfile %>',
    ABSTRACT_FROM => '<%= $c->mainfile %>',
    LICENSE       => '<%= $c->config('license') || 'perl' %>',
    META_MERGE => {
        resources => {
            repository => '<%= $c->repository %>',
        },
    },
);
EOT
};

file 'cpanfile' => content { return <<'EOT';
on 'test' => sub {
    requires 'Test::More' => '0.88'; # for done_testing
    requires 'Test::UseAllModules' => '0.10';
};
EOT
};

1;

__END__

=head1 NAME

Module::New::File::MakeMakerCPANfile

=head1 DESCRIPTION

a template for C<Makefile.PL> (with L<ExtUtils::MakeMaker::CPANfile>).

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
