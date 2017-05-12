package Pointer::int;
use Pointer -Base;
use Config;

const type => 'int';
const sizeof => $Config{intsize};
const pack_template => 'i!';
