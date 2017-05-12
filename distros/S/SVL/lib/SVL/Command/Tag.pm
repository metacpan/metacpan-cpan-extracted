
package SVL::Command::Tag;
use strict;
use warnings;
use Path::Class;
use base qw(SVL::Command);
use constant subcommands => qw(list delete);


sub run {
  my ($self, $target, @tags) = @_;

  my $sharing =
      SVL::Sharing->new(file($self->svkpath, 'svl-share'), $self->xd);

  my ($sharing_target, $sharing_path, $sharing_depot) = 
      $self->get_share_args($sharing, $target);

  my @origtags = $sharing->get_tags( $sharing_target, $sharing_path, $sharing_depot);

  my %origtags;
  @origtags{@origtags, @tags} = ();
  $sharing->set_tags($sharing_target, $target, keys %origtags);
  $self->SVL::Command::Tag::list::run($target);
}

sub get_share_args {
    my $self = shift;
    my $sharing = shift;
    my $inpath = shift;

    my ($share_path, $path, $depot, $target) =    
	$sharing->map_path_to_depot($inpath);

    $inpath =~s[/(.*?)/][/];
    return ($target, $inpath, $depot);
    
}

package SVL::Command::Tag::delete;
use strict;
use warnings;
use Path::Class;
use base qw(SVL::Command::Tag);

sub run {
  my ($self, $target, @tags) = @_;
    
  my $sharing =
      SVL::Sharing->new(file($self->svkpath, 'svl-share'), $self->xd);
  
  my ($sharing_target, $sharing_path, $sharing_depot) = 
      $self->get_share_args($sharing, $target);

  my @origtags = $sharing->get_tags( $sharing_target, $sharing_path, $sharing_depot);
  
  my %origtags;
  @origtags{@origtags} = ();
  foreach my $tag (@tags) {
      delete $origtags{$tag};
  }
  
  $sharing->set_tags($sharing_target, $target, keys %origtags);
  $self->SVL::Command::Tag::list::run($target);

}

package SVL::Command::Tag::list;
use strict;
use warnings;
use Path::Class;
use base qw(SVL::Command::Tag);

sub run {
    my ($self, $target) = @_;


  my $sharing =
      SVL::Sharing->new(file($self->svkpath, 'svl-share'), $self->xd);

    print "Tags: " .  join (" ", $sharing->get_tags( $self->get_share_args($sharing, $target) )) . "\n";
}

1;

__END__

=head1 NAME

SVL::Command::Share - Share a local repository

=head1 SYNOPSIS

  svl tag //trunk/Acme-Colour/ tag tag tag
  svl tag //trunk/Acme-Colour/ --list
  svl tag //trunk/Acme-Colour/ --delete tag_to_remove


=head1 OPTIONS

--list # show all tags
--delete deletes a given tag
