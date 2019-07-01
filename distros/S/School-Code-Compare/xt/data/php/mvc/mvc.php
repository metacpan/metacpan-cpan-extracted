// source: https://r.je/mvc-in-php.html
class Model {

    public $text; // public variable

    public function __construct() {
        $this->text = 'Hello world!';
    }        
}

class View {

    private $model;

    public function __construct(Model $model) {
        $this->model = $model;
    }

    public function output() {
        return '<h1>' . $this->model->text .'</h1>';
    }
}

class Controller {

    private $model;

    public function __construct(Model $model) {
        $this->model = $model;
    }
}


//initiate the triad
$model = new Model();

//It is important that the controller and the view share the model
$controller = new Controller($model);

$view = new View($model);
echo $view->output();
