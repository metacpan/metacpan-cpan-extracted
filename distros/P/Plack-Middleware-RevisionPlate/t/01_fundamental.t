use strict;
use warnings;
use Test::More;

use Plack::Middleware::RevisionPlate;

note 'revision_filename fallbacks to default if not specified';
my $with_default_revision_filename = Plack::Middleware::RevisionPlate->new( path => '/somepath' );
is $with_default_revision_filename->path, '/somepath';
is $with_default_revision_filename->_revision_filename, './REVISION', 'fallback to default';

is $with_default_revision_filename->_read_revision_file_at_first, undef, 'revision file not exists, so undef';

note 'specified EXISTS revision_filename';
my $with_exists_revision_file = Plack::Middleware::RevisionPlate->new( path => '/otherpath', revision_filename => 't/assets/REVISION_FILE' );
is $with_exists_revision_file->path, '/otherpath';
is $with_exists_revision_file->_revision_filename, 't/assets/REVISION_FILE', 'specified filename';
is $with_exists_revision_file->_read_revision_file_at_first, "deadbeaf\n", 'Can read content of revision_file';

done_testing;
