// source: https://r.je/mvc-in-php.html
class Model {

    public $txt;

    public function __construct() {
        $this->txt = 'Hi world!';
    }        
}

class View {

    private $model;

    public function __construct(Model $model) {
        $this->model = $model;
    }

    public function output() {
        return '<h1>' . $this->model->txt .'</h1>';
    }
}

class Controller {

    private $model;

    public function __construct(Model $model) {
        $this->model = $model;
    }
}


$model = new Model();

$controller = new Controller($model);

$view = new View($model);
echo $view->output();
