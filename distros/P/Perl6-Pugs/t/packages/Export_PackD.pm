use v6-alpha;

module t::packages::Export_PackD {
  sub this_gets_exported_lexically () is export {
    'moose!'
  }
}
