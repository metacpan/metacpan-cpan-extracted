package Object;

use TrackDirty;

has foo => (is => 'rw', isa => 'Str');

no TrackDirty;

1;
