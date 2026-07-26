use v5.40;
use feature 'class';
no warnings 'experimental::class';

package Net::BitTorrent::Types v2.1.1 {
    use Exporter qw[import];
    our @EXPORT = qw[
        ENCRYPTION_NONE
        ENCRYPTION_PREFERRED
        ENCRYPTION_REQUIRED
        STATE_STOPPED
        STATE_STARTING
        STATE_RUNNING
        STATE_PAUSED
        STATE_METADATA
        PICK_SEQUENTIAL
        PICK_RAREST_FIRST
        PICK_STREAMING
    ];
    our @EXPORT_OK   = @EXPORT;
    our %EXPORT_TAGS = (
        all        => \@EXPORT_OK,
        encryption => [qw[ENCRYPTION_NONE ENCRYPTION_PREFERRED ENCRYPTION_REQUIRED]],
        state      => [qw[STATE_STOPPED STATE_STARTING STATE_RUNNING STATE_PAUSED STATE_METADATA]],
        pick       => [qw[PICK_SEQUENTIAL PICK_RAREST_FIRST PICK_STREAMING]],
    );
    use constant {
        ENCRYPTION_NONE      => 0,
        ENCRYPTION_PREFERRED => 1,
        ENCRYPTION_REQUIRED  => 2,
        STATE_STOPPED        => 0,
        STATE_STARTING       => 1,
        STATE_RUNNING        => 2,
        STATE_PAUSED         => 3,
        STATE_METADATA       => 4,
        PICK_SEQUENTIAL      => 0,
        PICK_RAREST_FIRST    => 1,
        PICK_STREAMING       => 2,
    };
};
1;
