use strict; use warnings;
package Module::Compile::Opt;

# TODO; What is this module for?
# sub import {
#     my ($class, @args) = @_;
#     my $opts = $class->get_options(@args)
#         if $class->can('get_options');
#     $class->sanity_check($opts);
#     require Module::Compile;
#     require Module::Compile::Ext;
#     Module::Compile::Ext->import(@{$opts->{ext}});
#
#     # put coderef into @INC
#     # Store PERL5OPT in .author
#     # In Module::Compile, complain if PERL5OPT != .author/PERL5OPT
# }

sub sanity_check {
    my $class = shift;
    die unless -e 'inc' and -e 'Makefile.PL';
}

1;
