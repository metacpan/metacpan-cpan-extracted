##
# name:      Module::Install::TestCommon
# abstract:  Test::Common support for Module::Install
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

use 5.008003;
package Module::Install::TestCommon;
use strict;
use warnings;

use base 'Module::Install::Base';

our $VERSION = '0.07';
our $AUTHOR_ONLY = 1;

sub test_common_update {
    my $self = shift;
    return unless $self->is_admin;
    system("test-common update") == 0 or die $!;
    require Test::Common;
    $self->clean_files(Test::Common::clean_files());
}

1;
