#! /usr/bin/env perl

my $prefix= 'glducktape_';
my $c;
my $h= <<"END";
#include <GL/gl.h>
#include <GL/glext.h>
extern void* ${prefix}initProcAddress(const char *name, void **fnptr);
END

my $ver= '';
while (<STDIN>) {
	my ($maj, $min, $fn)= ($_ =~ /^(\d)\.(\d) (\w+)$/)
		or die "Invalid function spec $_";
	if ("GL_VERSION_${maj}_${min}" ne $ver) {
		if ($ver) { $h .= "#endif /* $ver */\n"; $c .= "#endif /* $ver */\n"; }
		$ver= "GL_VERSION_${maj}_${min}";
		$h .= "#ifdef $ver\n";
		$c .= "#ifdef $ver\n";
	}
	my $typedef= 'PFN'.uc($fn).'PROC';
	$h .= <<"END";
 extern $typedef $prefix$fn;
 #define $fn ($prefix$fn? $prefix$fn : ($typedef)${prefix}initProcAddress("$fn",(void**)&$prefix$fn))

END
	$c .= <<"END";
  $typedef $prefix$fn = NULL;
END
}
$h .= "#endif /* $ver */\n";
$c .= "#endif /* $ver */\n";

$c.= <<"END";

#if defined(_WIN32) || defined(__CYGWIN__)
#include <windows.h>
static HMODULE ${prefix}libGL;

typedef void* (APIENTRYP PFNWGLGETPROCADDRESSPROC_PRIVATE)(const char*);
static PFNWGLGETPROCADDRESSPROC_PRIVATE ${prefix}GetProcAddressPtr;

#ifdef _MSC_VER
#ifdef __has_include
  #if __has_include(<winapifamily.h>)
    #define HAVE_WINAPIFAMILY 1
  #endif
#elif _MSC_VER >= 1700 && !_USING_V110_SDK71_
  #define HAVE_WINAPIFAMILY 1
#endif
#endif

#ifdef HAVE_WINAPIFAMILY
  #include <winapifamily.h>
  #if !WINAPI_FAMILY_PARTITION(WINAPI_PARTITION_DESKTOP) && WINAPI_FAMILY_PARTITION(WINAPI_PARTITION_APP)
    #define IS_UWP 1
  #endif
#endif

static
int open_gl(void) {
#ifndef IS_UWP
    ${prefix}libGL = LoadLibraryW(L"opengl32.dll");
    if(${prefix}libGL != NULL) {
        void (* tmp)(void);
        tmp = (void(*)(void)) GetProcAddress(${prefix}libGL, "wglGetProcAddress");
        ${prefix}GetProcAddressPtr = (PFNWGLGETPROCADDRESSPROC_PRIVATE) tmp;
        return ${prefix}GetProcAddressPtr != NULL;
    }
#endif

    return 0;
}

#else
#include <dlfcn.h>
static void* ${prefix}libGL;

#if !defined(__APPLE__) && !defined(__HAIKU__)
typedef void* (APIENTRYP PFNGLXGETPROCADDRESSPROC_PRIVATE)(const char*);
static PFNGLXGETPROCADDRESSPROC_PRIVATE ${prefix}GetProcAddressPtr;
#endif

static
int open_gl(void) {
#ifdef __APPLE__
    static const char *NAMES[] = {
        "../Frameworks/OpenGL.framework/OpenGL",
        "/Library/Frameworks/OpenGL.framework/OpenGL",
        "/System/Library/Frameworks/OpenGL.framework/OpenGL",
        "/System/Library/Frameworks/OpenGL.framework/Versions/Current/OpenGL"
    };
#else
    static const char *NAMES[] = {"libGL.so.1", "libGL.so"};
#endif

    unsigned int index = 0;
    for(index = 0; index < (sizeof(NAMES) / sizeof(NAMES[0])); index++) {
        ${prefix}libGL = dlopen(NAMES[index], RTLD_NOW | RTLD_GLOBAL);

        if(${prefix}libGL != NULL) {
#if defined(__APPLE__) || defined(__HAIKU__)
            return 1;
#else
            ${prefix}GetProcAddressPtr = (PFNGLXGETPROCADDRESSPROC_PRIVATE)dlsym(${prefix}libGL,
                "glXGetProcAddressARB");
            return ${prefix}GetProcAddressPtr != NULL;
#endif
        }
    }

    return 0;
}

#endif

void* ${prefix}initProcAddress(const char *name, void **fnptr) {
    void* result = NULL;
	if (!${prefix}libGL) {
		open_gl();
		if (!${prefix}libGL)
			croak("Can't load OpenGL library");
	}

#if !defined(__APPLE__) && !defined(__HAIKU__)
    if(${prefix}GetProcAddressPtr != NULL) {
        result = ${prefix}GetProcAddressPtr(name);
    }
#endif
    if(result == NULL) {
#if defined(_WIN32) || defined(__CYGWIN__)
        result = (void*)GetProcAddress((HMODULE) ${prefix}libGL, name);
#else
        result = dlsym(${prefix}libGL, name);
#endif
    }
	if (!result)
		croak("Can't look up address of %s", name);
	*fnptr= result;
    return result;
}
END

print $h.$c;
