use strict;
use v5.22;

use Test::More tests => 3;

use File::Slurp;
use School::Code::Simplify::Comments;

my $simplifier = School::Code::Simplify::Comments->new();

my @lines = read_file( 't/simplify/slashy/mvc.php', binmode => ':utf8' );

my $clean = $simplifier->slashy(\@lines);

is($clean->{visibles}, 'classModel{public$text;publicfunction__construct(){$this->text=\'Helloworld!\';}}classView{private$model;publicfunction__construct(Model$model){$this->model=$model;}publicfunctionoutput(){return\'<h1>\'.$this->model->text.\'</h1>\';}}classController{private$model;publicfunction__construct(Model$model){$this->model=$model;}}$model=newModel();$controller=newController($model);$view=newView($model);echo$view->output();', 'phpmvc_visibles');
is($clean->{signes},   '{$;__(){$->=\'!\';}}{$;__($){$->=$;}(){\'<>\'.$->->.\'</>\';}}{$;__($){$->=$;}}$=();$=($);$=($);$->();', 'phpmvc_signes');
is($clean->{signes_ordered}, '$->();$->=$;$->=$;$->=\'!\';$;$;$;$=($);$=($);$=();\'<>\'.$->->.\'</>\';(){__($){__($){__(){{{{}}}}}}}', 'phpmvc_signesordered');
