package Template::TT2Site::Plugin::Mapper;

use strict;
use Template::Plugin;
use Text::ParseWords;

use vars qw( $VERSION );
use base qw( Template::Plugin );

$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

my $error = 0;
my $map;
my $trace;
my $verbose;

sub new {
    my $config = ref($_[-1]) eq 'HASH' ? pop(@_) : { };
    my ($class, $context) = @_;
    my $self = {};
    my $stash = $context->stash;

    $trace   = $config->{trace};
    $verbose = $config->{verbose};

    bless $self, $class;	# unused

    $error = 0;
    my $languages = $stash->get([qw(site 0 languages 0)]);

    unless ( $map ) {
	my $srcdir = File::Spec->catfile($stash->get('rootdir'),
					 $stash->get('tmplsrc'));

	if ( $languages ) {
	    warn("Mapper: Creating map for languages ",
		 join(", ", @$languages), ".\n") if $verbose;

	    foreach my $lang ( @$languages ) {
		my $dir = File::Spec->catfile($srcdir, $lang);
		unless ( -d $dir ) {
		    warn("Mapper: Missing directory for language ",
			 $lang, "\n") if $verbose;
		    next;
		}
		$map->{$lang} = $self->_do_map($dir);
	    }
	}
	else {
	    warn("Mapper: Creating site map\n") if $trace;
	    $map = $self->_do_map($srcdir);
	}

	$self->throw("Errors detected\n") if $error;
    }
    elsif ( $trace ) {
	print STDERR ("Mapper: Reusing cached map");
	print STDERR (" for language ",
		      $stash->get([qw(site 0 lang 0)]))
	  if $languages;
	print STDERR ("\n");
    }

    if ( $languages ) {
	$stash->set([qw(site 0 map 0)],
		    $map->{$stash->get([qw(site 0 lang 0)])});
    }
    else {
	$stash->set([qw(site 0 map 0)], $map);
    }
}

################ Subroutines ################

sub throw {
    my ($self, $error) = @_;
    die(Template::Exception->new('Mapper', $error));
}

sub _do_map {
    my ($self, $cur) = @_;
    my $map = "$cur/.map";
    my $m = {};
    unless ( -s $map && -r _ ) {
	warn("Mapper: Missing: $map\n");
	return $m;
    }
    warn("Mapper: Process: $map\n") if $verbose;

    open (my $mf, "<$map") or $self->throw("$map: $!\n");
    while ( <$mf> ) {
	chomp;
	next if /^\s*#/;
	next unless /\S/;
	my @w = shellwords($_);
	if ( $w[0] eq "title" && @w == 2 ) {
	    $m->{title} = $w[1];
	}
	elsif ( $w[0] eq "name" && @w == 2 ) {
	    $m->{name} = $w[1];
	}
	elsif ( $w[0] eq "menu" && @w == 3 ) {
	    $m->{menu} ||= [];
	    my $tag = $w[2];
	    $tag = sprintf("menu%02d", 1+scalar(@{$m->{menu}}))
	      if $tag !~ /^\w+$/;
	    push(@{$m->{menu}}, $tag);
	    if ( -f "$cur/$w[2].html" ) {
		$m->{page}->{$tag}->{name} = $w[1];
	    }
	    elsif ( -d "$cur/".$w[2] ) {
		$m->{page}->{$tag} = {
				      name => $w[1],
				      %{$self->_do_map("$cur/$w[2]")},
				     };
	    }
	    else {
		$m->{page}->{$tag}->{name} = $w[1];
		$m->{page}->{$tag}->{file} = $w[2];
	    }
	}
	else {
	    warn("Mapper: Invalid entry in .map: $_\n");
	    $error++;
	}
    }
    $m;
}

1;

__END__
