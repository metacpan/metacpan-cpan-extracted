use Test2::V0;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;
use Net::Google::Drive::Simple::V3;

my $gd = Net::Google::Drive::Simple::V3->new();
isa_ok( $gd, 'Net::Google::Drive::Simple::V3' );
can_ok(
    $gd,
    qw<
      new
      about
      getStartPageToken
      changes
      watch_changes
      stop_channels
      create_comment
      delete_comment
      get_comment
      comments
      update_comment
      copy_file
      create_file
      upload_media_file
      upload_multipart_file
      create_resumable_upload_for
      create_resumable_upload
      upload_file_content_single
      upload_file_content_multiple
      upload_file_content_iterator
      upload_file
      delete_file
      export_file
      generateIds
      get_file
      files
      update_file
      update_file_metadata
      watch_file
      empty_trash
      create_permission
      delete_permission
      get_permission
      permissions
      update_permission
      create_reply
      delete_reply
      get_reply
      replies
      update_reply
      delete_revision
      get_revision
      revisions
      update_revision
      create_drive
      delete_drive
      get_drive
      hide_drive
      drives
      unhide_drive
      update_drive
      children
      children_by_folder_id
    >,
);

done_testing();
