import os
import sys

import hdf5storage
import numpy as np
import scipy.io as io

bo = '_le' if sys.byteorder == 'little' else '_be'

var = {}
var['struct1'] = {}
var['struct1']['a']=16
var['struct1']['b']=32

io.savemat(f'packed_field_name_uncompressed{bo}.mat', var, do_compression=False)
io.savemat(f'packed_field_name_compressed{bo}.mat', var, do_compression=True)

var = {'var': {}}
var['var']['data'] = np.eye(3)
file_name = f'struct_nullpad_class_name_hdf{bo}.mat'
try:
    os.remove(file_name)
except OSError:
    pass
hdf5storage.savemat(file_name, var, store_python_metadata=False)
