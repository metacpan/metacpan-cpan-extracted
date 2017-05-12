package Pointer::long;
use Pointer -Base;
use Config;

const type => 'long';
const sizeof => $Config{longsize};
