lsf_node0(){
  t=($LSB_HOSTS)
  return ${t[0]}
}

lsf_master(){
  return $LSB_SUB_HOST
}
