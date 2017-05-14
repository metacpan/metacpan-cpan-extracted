package Ovid::Package;
use strict;

use Ovid::Common;
use Ovid::Error;
use POSIX qw/strftime/;
use File::Basename;
use File::Copy;

@Ovid::Package::ISA = qw(Ovid::Common Ovid::Error);

our @macros = qw(rpmdir sourcedir specdir);

sub accessors
{
  return {scalar => [qw(forcebuild logfile skipbuild rpm_bin rpmbuild_bin 
                        rpm_name name version builder basedir license installdirs
                        archive description date buildroot tmpdir build_dir packager), @macros],
                     
          array => [qw(provides requires)]};
}

sub defaults
{
    return {
            license => 'Perl/Artistic License?',
            date => POSIX::strftime('%a %b %d %Y', localtime()),
           };
}

sub init
{
  my $self = shift;
  
  #Find binaries.
  my @bin = qw(rpm);
  while (my $b = pop @bin){
    my $bin = $self->find_exec($b);
    fatal "cannot find required binary [$b]" unless $bin;
    my $n = "${b}_bin";
    if (my $s = $self->can($n)){
      $s->($self, $bin);
    }
    else {
      fatal "required accessor [$n] is undeclared";
    }
    #rpm 4.x uses rpmbuild instead of rpm
    if ($b eq 'rpm'){
     my $t = `$bin --version`;
     if ($t =~ m/3.\d.\d\s*$/){
        $self->rpmbuild_bin($bin);
     }
     else {
        push @bin, 'rpmbuild';
     }
    }
  }
  
  $self->load_macros(@macros); 

}

sub interrogate
{
  my ($self, $obj) = @_;
  my %map = (
             'version' => 'cpan_version',               
             'archive' => 'cpan_file',
             'provides' => 'containsmods',
            );
  
  while (my ($k, $v) = each %map){
    if ($obj->can($v)){
      my ($name, $type) = split /:/, $k;
      if (my $sub = $self->can($name)){
          $sub->($self, $obj->$v());         
      }
      else {
       fatal "required accessor [$name] is undeclared";
      }
    }
  }

  $self->parse_archive;
}

sub load_macros
{
  my $self = shift;

  my $rpm_bin = $self->rpm_bin;
  
  for my $m (@_){
    my $s = qq[%{_${m}}];
    my $t = qx/$rpm_bin --eval '$s'/;
    chomp $t;
    fatal "rpm macro [$m] is undefined" if $s eq $t;
    $self->$m($t);
  }
}

sub get_description
{
  my ($self, $buildir) = @_;
  my $f = qq[$buildir/README];
  if (-f $f){
    if (open(F, $f)){
        my @t;
        while(<F>){
            push @t, $_;
            last if /^INSTALL/;
        }
        close F;
        if (@t){
          $self->description(join '', @t);
          return 1;
        }
    }
  }
}

sub specfile
{
  my $self = shift;
  my $n = $self->name_string;
  my $d = $self->specdir;
  return qq[${d}/perl-${n}.spec];
}

sub provreq
{
  my ($self,$name, $op, $version) = @_;
  my @x = (qq[perl($name)]);
  if ($version && $version ne '0'){
    push @x, $op, $version;
  }
  return join ' ', @x;
}

sub requires_string
{
  my $self = shift;
  my @t = @_ || $self->requires;

  return unless scalar @t;

  my @out; 
  for my $r (@t)
    {
      push @out, $self->provreq($r->{name}, '>=', $r->{version});
    }
  return unless @out;
  return join('', 'Requires: ',  join ' ', @out); 
}

sub provides_string
{
  my $self = shift;
  my @t = $self->provides;

  return unless @t;
  
  my @out; 
  for my $n (@t){ 
    push @out, $self->provreq($n);
  }

  return join('', 'Provides: ', join ' ', @out);
}

sub name_string
{
  my $self = shift;
  my %args = @_;
  
  my @name = ($self->rpm_name);
  #$name[0] =~ s/::/-/g;
  
  push(@name, '-', $self->version) if exists $args{with_version};
  unshift(@name, 'perl-') if exists $args{prefixed};
  return join '', @name;
}

sub parse_archive 
{
  my $self = shift;
  my $t = $self->archive;
  
  if ($t =~ /^Contact Author/) {
    fatal "package [@{[$self->name]}] says: $t\n";
  }

  $t =~ s/(\.(?:tar\.gz|tgz|zip|gz|pm\.gz|pm))$//;

  if ($t =~ m<([^/]+?)[-._]?v?-?([-_.\d]+[a-z]*?\d*)$>){
      $self->rpm_name($1);
      $self->version($2);
  }
  else {
    fatal "cannot parse archive name [@{[$self->archive]}]";
  }
}

sub make_spec
{
  my ($self) = @_;
  
  my $t = $self->accessors;
  my %macros;

  for my $m (@{$t->{scalar}}){
    $macros{$m} = $self->$m;
  }
 
  $macros{buildroot} ||= $self->tmpdir;
  
  #not much savings here with 3 items
  for my $n (qw(provides requires name)){
    my $sub_name = qq[${n}_string]; 
    if (my $sub_ref = $self->can($sub_name)){
      $macros{$n} = $sub_ref->($self); 
    }
    else {
        fatal "required accessor [$sub_name] is not defined";
    }
  }

  for my $t (qw(builder archive build_dir)){
    $macros{$t} = basename($macros{$t});
  }

  my $template = $self->spec_template();
  
  while (my ($name, $value) = each %macros)
  {
    $template =~ s/\@$name\@/$value/ge;
  }
  
  my $specfile = $self->specfile;
  open(F, ">$specfile") or fatal "cannot open spec file for writing. $!";
  print F $template;
  close F;

  return $specfile;
}

sub make_rpm
{
  my $self = shift;
  my $specfile = $self->make_spec;

  return if $self->skipbuild;
  
  unless ($self->forcebuild){
    
    if (my $t = $self->rpm_is_installed){
      info "skipping rebuild for installed rpm $t";
      return;
    }
    
    if (my $t = $self->rpm_is_on_disk){
        info "skipping rebuild for existing rpm file $t";
        return;
    }
  }
  
  $self->copy_sources;
  system($self->rpmbuild_bin, '-ba', $specfile);
}

sub rpm_is_installed
{
  my ($self) = @_;
  my $rpm_bin = $self->rpm_bin;
  my $version = $self->version;

  for my $name_ver ($self->name_string(with_version => 1),
                $self->name_string(with_version => 1, prefixed => 1)){
    #old versions of rpm print errors to stderr, while new ones send to stdout.
    my $t = qx(exec 2>&1; $rpm_bin -q $name_ver --queryformat '%{version}');
    chomp $t;
    if ($t =~ /^$version/){
      return $name_ver;
    }
  }
}

sub rpm_is_on_disk
{
  my ($self, $dir) = @_;

  $dir ||= $self->rpmdir;

  my @names = ($self->name_string(with_version => 1),
               $self->name_string(with_version => 1, prefixed => 1));


  my $found;
  opendir(D, $dir) or fatal "cannot open directory $dir. $!";

  my @dirs;
  MAIN:
  for my $t (readdir(D))
  {
    my $p =qq[$dir/$t]; 
    if ( -d $p ){
      push @dirs, $p unless $t =~ /^\.\.?$/;
    }
    else {
      for my $name_ver (@names){
        if ($t =~ /^$name_ver/){
          $found=$name_ver;
          last MAIN;
        }
      }
    }
  }
  
  closedir (D);
  return $found if $found;
  
  for my $d (@dirs){
    if (my $t = $self->rpm_is_on_disk($d)){
      return $t;
    }
  }
  
  return undef;
}

sub copy_sources
{
  my $self = shift;
  
  my $source = join('/', $self->basedir, $self->archive);
  my $target = join('/', $self->sourcedir, basename($source));
  
  unless(copy($source, $target)){
    warning "error copying file [$source] to [$target]. $!";
  }
}

sub spec_template
{
    return(<<'EOF'); 
%define _unpackaged_files_terminate_build 0
Summary: perl-@name@ 
Name: perl-@name@ 
Version: @version@ 
Release: 1
License: @license@
Group: Applications/CPAN
Source: @archive@ 
BuildRoot: @buildroot@/@name@
Packager: @packager@ 
AutoReq: no
AutoReqProv: no
@requires@
@provides@

%description
@description@

%prep
%setup -q -n @build_dir@

%build
CFLAGS="$RPM_OPT_FLAGS $CFLAGS" perl @builder@ 
make

%clean 
if [ "%{buildroot}" != "/" ]; then
  rm -rf %{buildroot} 
fi


%install

make PREFIX=%{_prefix} \
     DESTDIR=%{buildroot} \
     INSTALLDIRS=@installdirs@ \
     install

[ -x /usr/lib/rpm/brp-compress ] && /usr/lib/rpm/brp-compress

find ${RPM_BUILD_ROOT} \
  \( -path '*/perllocal.pod' -o -path '*/.packlist' -o -path '*.bs' \) -a -prune -o \
  -type f -printf "/%%P\n" > @name@-filelist

if [ "$(cat @name@-filelist)X" = "X" ] ; then
    echo "ERROR: EMPTY FILE LIST"
    exit 1
fi

%files -f @name@-filelist
%defattr(-,root,root)

%changelog
* @date@ @packager@ 
- Initial build
EOF
}

1;
