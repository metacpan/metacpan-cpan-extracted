package UseCallSeparatePackages1;
use Try::Tiny;
package UseCallSeparatePackages2;
try {
    print 'Hello world!';
};
