use strict;
use v5.6.0;

use Test::More tests => 4;

use File::Slurp;
use School::Code::Compare::Charset;

my $charset = School::Code::Compare::Charset->new()->set_language('slashy');

my @lines = read_file( 'xt/data/php/mvc/mvc.php', binmode => ':utf8' );

my $visibles = $charset->get_visibles(\@lines);

is(join('',@{$visibles}), 'classModel{public$text;publicfunction__construct(){$this->text=\'Helloworld!\';}}classView{private$model;publicfunction__construct(Model$model){$this->model=$model;}publicfunctionoutput(){return\'<h1>\'.$this->model->text.\'</h1>\';}}classController{private$model;publicfunction__construct(Model$model){$this->model=$model;}}$model=newModel();$controller=newController($model);$view=newView($model);echo$view->output();', 'phpmvc_visibles');

my $signes = $charset->get_signes(\@lines);

is(join('',@{$signes}), '{$;(){$->=\'!\';}}{$;($){$->=$;}(){\'<>\'.$->->.\'</>\';}}{$;($){$->=$;}}$=();$=($);$=($);$->();', 'phpmvc_signes');

$charset = School::Code::Compare::Charset->new()->set_language('slashy');

   $signes         = $charset->get_signes(\@lines);
my $signes_ordered = $charset->sort_by_lines($signes);

is(join('',@{$signes_ordered}), '$->();$->=$;$->=$;$->=\'!\';$;$;$;$=($);$=($);$=();\'<>\'.$->->.\'</>\';($){($){(){(){{{{}}}}}}}', 'phpmvc_signesordered');

$charset = School::Code::Compare::Charset->new()->set_language('slashy');

   $visibles         = $charset->get_visibles(\@lines);
my $visibles_ordered = $charset->sort_by_lines($visibles);

is(join('',@{$visibles_ordered}), '$controller=newController($model);$model=newModel();$this->model=$model;$this->model=$model;$this->text=\'Helloworld!\';$view=newView($model);classController{classModel{classView{echo$view->output();private$model;private$model;public$text;publicfunction__construct(){publicfunction__construct(Model$model){publicfunction__construct(Model$model){publicfunctionoutput(){return\'<h1>\'.$this->model->text.\'</h1>\';}}}}}}}', 'phpmvc_visiblesordered');
