=head1 NAME

OpenCL - Open Computing Language Bindings

=head1 SYNOPSIS

 use OpenCL;

=head1 DESCRIPTION

This is an early release which might be useful, but hasn't seen much testing.

=head2 OpenCL FROM 10000 FEET HEIGHT

Here is a high level overview of OpenCL:

First you need to find one or more OpenCL::Platforms (kind of like
vendors) - usually there is only one.

Each platform gives you access to a number of OpenCL::Device objects, e.g.
your graphics card.

From a platform and some device(s), you create an OpenCL::Context, which is
a very central object in OpenCL: Once you have a context you can create
most other objects:

OpenCL::Program objects, which store source code and, after building for a
specific device ("compiling and linking"), also binary programs. For each
kernel function in a program you can then create an OpenCL::Kernel object
which represents basically a function call with argument values.

OpenCL::Memory objects of various flavours: OpenCL::Buffer objects (flat
memory areas, think arrays or structs) and OpenCL::Image objects (think 2D
or 3D array) for bulk data and input and output for kernels.

OpenCL::Sampler objects, which are kind of like texture filter modes in
OpenGL.

OpenCL::Queue objects - command queues, which allow you to submit memory
reads, writes and copies, as well as kernel calls to your devices. They
also offer a variety of methods to synchronise request execution, for
example with barriers or OpenCL::Event objects.

OpenCL::Event objects are used to signal when something is complete.

=head2 HELPFUL RESOURCES

The OpenCL specs used to develop this module - download these and keept
hema round, they are required reference material:

   http://www.khronos.org/registry/cl/specs/opencl-1.1.pdf
   http://www.khronos.org/registry/cl/specs/opencl-1.2.pdf
   http://www.khronos.org/registry/cl/specs/opencl-1.2-extensions.pdf

OpenCL manpages:

   http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/
   http://www.khronos.org/registry/cl/sdk/1.2/docs/man/xhtml/

If you are into UML class diagrams, the following diagram might help - if
not, it will be mildly confusing (also, the class hierarchy of this module
is much more fine-grained):

   http://www.khronos.org/registry/cl/sdk/1.2/docs/man/xhtml/classDiagram.html

Here's a tutorial from AMD (very AMD-centric, too), not sure how useful it
is, but at least it's free of charge:

   http://developer.amd.com/zones/OpenCLZone/courses/Documents/Introduction_to_OpenCL_Programming%20Training_Guide%20%28201005%29.pdf

And here's NVIDIA's OpenCL Best Practises Guide:

   http://developer.download.nvidia.com/compute/cuda/3_2/toolkit/docs/OpenCL_Best_Practices_Guide.pdf

=head1 BASIC WORKFLOW

To get something done, you basically have to do this once (refer to the
examples below for actual code, this is just a high-level description):

Find some platform (e.g. the first one) and some device(s) (e.g. the first
device of the platform), and create a context from those.

Create program objects from your OpenCL source code, then build (compile)
the programs for each device you want to run them on.

Create kernel objects for all kernels you want to use (surprisingly, these
are not device-specific).

Then, to execute stuff, you repeat these steps, possibly resuing or
sharing some buffers:

Create some input and output buffers from your context. Set these as
arguments to your kernel.

Enqueue buffer writes to initialise your input buffers (when not
initialised at creation time).

Enqueue the kernel execution.

Enqueue buffer reads for your output buffer to read results.

=head1 EXAMPLES

=head2 Enumerate all devices and get contexts for them.

Best run this once to get a feel for the platforms and devices in your
system.

   for my $platform (OpenCL::platforms) {
      printf "platform: %s\n", $platform->name;
      printf "extensions: %s\n", $platform->extensions;
      for my $device ($platform->devices) {
         printf "+ device: %s\n", $device->name;
         my $ctx = $platform->context (undef, [$device]);
         # do stuff
      }
   }

=head2 Get a useful context and a command queue.

This is a useful boilerplate for any OpenCL program that only wants to use
one device,

   my ($platform) = OpenCL::platforms; # find first platform
   my ($dev) = $platform->devices;     # find first device of platform
   my $ctx = $platform->context (undef, [$dev]); # create context out of those
   my $queue = $ctx->queue ($dev);     # create a command queue for the device

=head2 Print all supported image formats of a context.

Best run this once for your context, to see whats available and how to
gather information.

   for my $type (OpenCL::MEM_OBJECT_IMAGE2D, OpenCL::MEM_OBJECT_IMAGE3D) {
      print "supported image formats for ", OpenCL::enum2str $type, "\n";
      
      for my $f ($ctx->supported_image_formats (0, $type)) {
         printf "  %-10s %-20s\n", OpenCL::enum2str $f->[0], OpenCL::enum2str $f->[1];
      }
   }

=head2 Create a buffer with some predefined data, read it back synchronously,
then asynchronously.

   my $buf = $ctx->buffer_sv (OpenCL::MEM_COPY_HOST_PTR, "helmut");

   $queue->read_buffer ($buf, 1, 1, 3, my $data);
   print "$data\n";

   my $ev = $queue->read_buffer ($buf, 0, 1, 3, my $data);
   $ev->wait;
   print "$data\n"; # prints "elm"

=head2 Create and build a program, then create a kernel out of one of its
functions.

   my $src = '
      kernel void
      squareit (global float *input, global float *output)
      {
        $id = get_global_id (0);
        output [id] = input [id] * input [id];
      }
   ';

   my $prog = $ctx->build_program ($src);
   my $kernel = $prog->kernel ("squareit");

=head2 Create some input and output float buffers, then call the
'squareit' kernel on them.

   my $input  = $ctx->buffer_sv (OpenCL::MEM_COPY_HOST_PTR, pack "f*", 1, 2, 3, 4.5);
   my $output = $ctx->buffer (0, OpenCL::SIZEOF_FLOAT * 5);

   # set buffer
   $kernel->set_buffer (0, $input);
   $kernel->set_buffer (1, $output);

   # execute it for all 4 numbers
   $queue->nd_range_kernel ($kernel, undef, [4], undef);

   # enqueue a synchronous read
   $queue->read_buffer ($output, 1, 0, OpenCL::SIZEOF_FLOAT * 4, my $data);

   # print the results:
   printf "%s\n", join ", ", unpack "f*", $data;

=head2 The same enqueue operations as before, but assuming an out-of-order queue,
showing off barriers.

   # execute it for all 4 numbers
   $queue->nd_range_kernel ($kernel, undef, [4], undef);

   # enqueue a barrier to ensure in-order execution
   $queue->barrier;

   # enqueue an async read
   $queue->read_buffer ($output, 0, 0, OpenCL::SIZEOF_FLOAT * 4, my $data);

   # wait for all requests to finish
   $queue->finish;

=head2 The same enqueue operations as before, but assuming an out-of-order queue,
showing off event objects and wait lists.

   # execute it for all 4 numbers
   my $ev = $queue->nd_range_kernel ($kernel, undef, [4], undef);

   # enqueue an async read
   $ev = $queue->read_buffer ($output, 0, 0, OpenCL::SIZEOF_FLOAT * 4, my $data, $ev);

   # wait for the last event to complete
   $ev->wait;

=head2 Use the OpenGL module to share a texture between OpenCL and OpenGL and draw some julia
set flight effect.

This is quite a long example to get you going - you can also download it
from L<http://cvs.schmorp.de/OpenCL/examples/juliaflight>.

   use OpenGL ":all";
   use OpenCL;

   my $S = $ARGV[0] || 256; # window/texture size, smaller is faster

   # open a window and create a gl texture
   OpenGL::glpOpenWindow width => $S, height => $S;
   my $texid = glGenTextures_p 1;
   glBindTexture GL_TEXTURE_2D, $texid;
   glTexImage2D_c GL_TEXTURE_2D, 0, GL_RGBA8, $S, $S, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0;

   # find and use the first opencl device that let's us get a shared opengl context
   my $platform;
   my $dev;
   my $ctx;

   for (OpenCL::platforms) {
      $platform = $_;
      for ($platform->devices) {
         $dev = $_;
         $ctx = $platform->context ([OpenCL::GLX_DISPLAY_KHR, undef, OpenCL::GL_CONTEXT_KHR, undef], [$dev])
            and last;
      }
   }

   $ctx
      or die "cannot find suitable OpenCL device\n";

   my $queue = $ctx->queue ($dev);

   # now attach an opencl image2d object to the opengl texture
   my $tex = $ctx->gl_texture2d (OpenCL::MEM_WRITE_ONLY, GL_TEXTURE_2D, 0, $texid);

   # now the boring opencl code
   my $src = <<EOF;
   kernel void
   juliatunnel (write_only image2d_t img, float time)
   {
     int2 xy = (int2)(get_global_id (0), get_global_id (1));
     float2 p = convert_float2 (xy) / $S.f * 2.f - 1.f;

     float2 m = (float2)(1.f, p.y) / fabs (p.x); // tunnel
     m.x = fabs (fmod (m.x + time * 0.05f, 4.f) - 2.f);

     float2 z = m;
     float2 c = (float2)(sin (time * 0.01133f), cos (time * 0.02521f));

     for (int i = 0; i < 25 && dot (z, z) < 4.f; ++i) // standard julia
       z = (float2)(z.x * z.x - z.y * z.y, 2.f * z.x * z.y) + c;

     float3 colour = (float3)(z.x, z.y, atan2 (z.y, z.x));
     write_imagef (img, xy, (float4)(colour * p.x * p.x, 1.));
   }
   EOF

   my $prog = $ctx->build_program ($src);
   my $kernel = $prog->kernel ("juliatunnel");

   # program compiled, kernel ready, now draw and loop

   for (my $time; ; ++$time) {
      # acquire objects from opengl
      $queue->acquire_gl_objects ([$tex]);

      # configure and run our kernel
      $kernel->setf ("mf", $tex, $time*2); # mf = memory object, float
      $queue->nd_range_kernel ($kernel, undef, [$S, $S], undef);

      # release objects to opengl again
      $queue->release_gl_objects ([$tex]);

      # wait
      $queue->finish;

      # now draw the texture, the defaults should be all right
      glTexParameterf GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST;

      glEnable GL_TEXTURE_2D;
      glBegin GL_QUADS;
         glTexCoord2f 0, 1; glVertex3i -1, -1, -1;
         glTexCoord2f 0, 0; glVertex3i  1, -1, -1;
         glTexCoord2f 1, 0; glVertex3i  1,  1, -1;
         glTexCoord2f 1, 1; glVertex3i -1,  1, -1;
      glEnd;

      glXSwapBuffers;

      select undef, undef, undef, 1/60;
   }

=head2 How to modify the previous example to not rely on GL sharing.

For those poor souls with only a sucky CPU OpenCL implementation, you
currently have to read the image into some perl scalar, and then modify a
texture or use glDrawPixels or so).

First, when you don't need gl sharing, you can create the context much simpler:

   $ctx = $platform->context (undef, [$dev])

To use a texture, you would modify the above example by creating an
OpenCL::Image manually instead of deriving it from a texture:

   my $tex = $ctx->image2d (OpenCL::MEM_WRITE_ONLY, OpenCL::RGBA, OpenCL::UNORM_INT8, $S, $S);

And in the draw loop, intead of acquire_gl_objects/release_gl_objects, you
would read the image2d after the kernel has written it:

   $queue->read_image ($tex, 0, 0, 0, 0, $S, $S, 1, 0, 0, my $data);

And then you would upload the pixel data to the texture (or use glDrawPixels):

   glTexSubImage2D_s GL_TEXTURE_2D, 0, 0, 0, $S, $S, GL_RGBA, GL_UNSIGNED_BYTE, $data;

The fully modified example can be found at
L<http://cvs.schmorp.de/OpenCL/examples/juliaflight-nosharing>.

=head2 Julia sets look soooo 80ies.

Then colour them differently, e.g. using orbit traps! Replace the loop and
colour calculation from the previous examples by this:

  float2 dm = (float2)(1.f, 1.f);

  for (int i = 0; i < 25; ++i)
    {
      z = (float2)(z.x * z.x - z.y * z.y, 2.f * z.x * z.y) + c;
      dm = fmin (dm, (float2)(fabs (dot (z, z) - 1.f), fabs (z.x - 1.f)));
    }

  float3 colour = (float3)(dm.x * dm.y, dm.x * dm.y, dm.x);

Also try C<-10.f> instead of C<-1.f>.

=head1 DOCUMENTATION

=head2 BASIC CONVENTIONS

This is not a one-to-one C-style translation of OpenCL to Perl - instead
I attempted to make the interface as type-safe as possible by introducing
object syntax where it makes sense. There are a number of important
differences between the OpenCL C API and this module:

=over 4

=item * Object lifetime managament is automatic - there is no need
to free objects explicitly (C<clReleaseXXX>), the release function
is called automatically once all Perl references to it go away.

=item * OpenCL uses CamelCase for function names
(e.g. C<clGetPlatformIDs>, C<clGetPlatformInfo>), while this module
uses underscores as word separator and often leaves out prefixes
(C<OpenCL::platforms>, C<< $platform->info >>).

=item * OpenCL often specifies fixed vector function arguments as short
arrays (C<size_t origin[3]>), while this module explicitly expects the
components as separate arguments (C<$orig_x, $orig_y, $orig_z>) in
function calls.

=item * Structures are often specified by flattening out their components
as with short vectors, and returned as arrayrefs.

=item * When enqueuing commands, the wait list is specified by adding
extra arguments to the function - anywhere a C<$wait_events...> argument
is documented this can be any number of event objects. As an extsnion
implemented by this module, C<undef> values will be ignored in the event
list.

=item * When enqueuing commands, if the enqueue method is called in void
context, no event is created. In all other contexts an event is returned
by the method.

=item * This module expects all functions to return C<OpenCL::SUCCESS>. If any
other status is returned the function will throw an exception, so you
don't normally have to to any error checking.

=back

=head2 CONSTANTS

All C<CL_xxx> constants that this module supports are always available
in the C<OpenCL> namespace as C<OpenCL::xxx> (i.e. without the C<CL_>
prefix). Constants which are not defined in the header files used during
compilation, or otherwise are not available, will have the value C<0> (in
some cases, this will make them indistinguishable from real constants,
sorry).

The latest version of this module knows and exports the constants
listed in L<http://cvs.schmorp.de/OpenCL/constiv.h>.

=head2 OPENCL 1.1 VS. OPENCL 1.2

This module supports both OpenCL version 1.1 and 1.2, although the OpenCL
1.2 interface hasn't been tested much for lack of availability of an
actual implementation.

Every function or method in this manual page that interfaces to a
particular OpenCL function has a link to the its C manual page.

If the link contains a F<1.1>, then this function is an OpenCL 1.1
function. Most but not all also exist in OpenCL 1.2, and this module
tries to emulate the missing ones for you, when told to do so at
compiletime. You can check whether a function was removed in OpenCL 1.2 by
replacing the F<1.1> component in the URL by F<1.2>.

If the link contains a F<1.2>, then this is a OpenCL 1.2-only
function. Even if the module was compiled with OpenCL 1.2 header files
and has an 1.2 OpenCL library, calling such a function on a platform that
doesn't implement 1.2 causes undefined behaviour, usually a crash (But
this is not guaranteed).

You can find out whether this module was compiled to prefer 1.1
functionality by ooking at C<OpenCL::PREFER_1_1> - if it is true, then
1.1 functions generally are implemented using 1.1 OpenCL functions. If it
is false, then 1.1 functions missing from 1.2 are emulated by calling 1.2
fucntions.

This is a somewhat sorry state of affairs, but the Khronos group choose to
make every release of OpenCL source and binary incompatible with previous
releases.

=head2 PERL AND OPENCL TYPES

This handy(?) table lists OpenCL types and their perl, PDL and pack/unpack
format equivalents:

   OpenCL    perl   PDL       pack/unpack
   char      IV     -         c
   uchar     IV     byte      C
   short     IV     short     s
   ushort    IV     ushort    S
   int       IV     long?     l
   uint      IV     -         L
   long      IV     longlong  q
   ulong     IV     -         Q
   float     NV     float     f
   half      IV     ushort    S
   double    NV     double    d

=head2 GLX SUPPORT

Due to the sad state that OpenGL support is in in Perl (mostly the OpenGL
module, which has little to no documentation and has little to no support
for glX), this module, as a special extension, treats context creation
properties C<OpenCL::GLX_DISPLAY_KHR> and C<OpenCL::GL_CONTEXT_KHR>
specially: If either or both of these are C<undef>, then the OpenCL
module tries to dynamically resolve C<glXGetCurrentDisplay> and
C<glXGetCurrentContext>, call these functions and use their return values
instead.

For this to work, the OpenGL library must be loaded, a GLX context must
have been created and be made current, and C<dlsym> must be available and
capable of finding the function via C<RTLD_DEFAULT>.

=head2 EVENT SYSTEM

OpenCL can generate a number of (potentially) asynchronous events, for
example, after compiling a program, to signal a context-related error or,
perhaps most important, to signal completion of queued jobs (by setting
callbacks on OpenCL::Event objects).

The OpenCL module converts all these callbacks into events - you can
still register callbacks, but they are not executed when your OpenCL
implementation calls the actual callback, but only later. Therefore, none
of the limitations of OpenCL callbacks apply to the perl implementation:
it is perfectly safe to make blocking operations from event callbacks, and
enqueued operations don't need to be flushed.

To facilitate this, this module maintains an event queue - each
time an asynchronous event happens, it is queued, and perl will be
interrupted. This is implemented via the L<Async::Interrupt> module. In
addition, this module has L<AnyEvent> support, so it can seamlessly
integrate itself into many event loops.

Since L<Async::Interrupt> is a bit hard to understand, here are some case examples:

=head3 Don't use callbacks.

When your program never uses any callbacks, then there will never be any
notifications you need to take care of, and therefore no need to worry
about all this.

You can achieve a great deal by explicitly waiting for events, or using
barriers and flush calls. In many programs, there is no need at all to
tinker with asynchronous events.

=head3 Use AnyEvent

This module automatically registers a watcher that invokes all outstanding
event callbacks when AnyEvent is initialised (and block asynchronous
interruptions). Using this mode of operations is the safest and most
recommended one.

To use this, simply use AnyEvent and this module normally, make sure you
have an event loop running:

   use Gtk2 -init;
   use AnyEvent;

   # initialise AnyEvent, by creating a watcher, or:
   AnyEvent::detect;

   my $e = $queue->marker;
   $e->cb (sub {
      warn "opencl is finished\n";
   })

   main Gtk2;

Note that this module will not initialise AnyEvent for you. Before
AnyEvent is initialised, the module will asynchronously interrupt perl
instead. To avoid any surprises, it's best to explicitly initialise
AnyEvent.

You can temporarily enable asynchronous interruptions (see next paragraph)
by calling C<$OpenCL::INTERRUPT->unblock> and disable them again by
calling C<$OpenCL::INTERRUPT->block>.

=head3 Let yourself be interrupted at any time

This mode is the default unless AnyEvent is loaded and initialised. In
this mode, OpenCL asynchronously interrupts a running perl program. The
emphasis is on both I<asynchronously> and I<running> here.

Asynchronously means that perl might execute your callbacks at any
time. For example, in the following code (I<THAT YOU SHOULD NOT COPY>),
the C<until> loop following the marker call will be interrupted by the
callback:

   my $e = $queue->marker;
   my $flag;
   $e->cb (sub { $flag = 1 });
   1 until $flag;
   # $flag is now 1

The reason why you shouldn't blindly copy the above code is that
busy waiting is a really really bad thing, and really really bad for
performance.

While at first this asynchronous business might look exciting, it can be
really hard, because you need to be prepared for the callback code to be
executed at any time, which limits the amount of things the callback code
can do safely.

This can be mitigated somewhat by using C<<
$OpenCL::INTERRUPT->scope_block >> (see the L<Async::Interrupt>
documentation for details).

The other problem is that your program must be actively I<running> to be
interrupted. When you calculate stuff, your program is running.  When you
hang in some C functions or other block execution (by calling C<sleep>,
C<select>, running an event loop and so on), your program is waiting, not
running.

One way around that would be to attach a read watcher to your event loop,
listening for events on C<< $OpenCL::INTERRUPT->pipe_fileno >>, using a
dummy callback (C<sub { }>) to temporarily execute some perl code.

That is then awfully close to using the built-in AnyEvent support above,
though, so consider that one instead.

=head3 Be creative

OpenCL exports the L<Async::Interrupt> object it uses in the global
variable C<$OpenCL::INTERRUPT>. You can configure it in any way you like.

So if you want to feel like a real pro, err, wait, if you feel no risk
menas no fun, you can experiment by implementing your own mode of
operations.

=cut

package OpenCL;

use common::sense;
use Carp ();
use Async::Interrupt ();

our $POLL_FUNC; # set by XS

BEGIN {
   our $VERSION = '1.01';

   require XSLoader;
   XSLoader::load (__PACKAGE__, $VERSION);

   @OpenCL::Platform::ISA      =
   @OpenCL::Device::ISA        =
   @OpenCL::Context::ISA       =
   @OpenCL::Queue::ISA         =
   @OpenCL::Memory::ISA        =
   @OpenCL::Sampler::ISA       =
   @OpenCL::Program::ISA       =
   @OpenCL::Kernel::ISA        =
   @OpenCL::Event::ISA         = OpenCL::Object::;

   @OpenCL::SubDevice::ISA     = OpenCL::Device::;

   @OpenCL::Buffer::ISA        =
   @OpenCL::Image::ISA         = OpenCL::Memory::;

   @OpenCL::BufferObj::ISA     = OpenCL::Buffer::;

   @OpenCL::Image2D::ISA       =
   @OpenCL::Image3D::ISA       =
   @OpenCL::Image2DArray::ISA  =
   @OpenCL::Image1D::ISA       =
   @OpenCL::Image1DArray::ISA  =
   @OpenCL::Image1DBuffer::ISA = OpenCL::Image::;

   @OpenCL::UserEvent::ISA     = OpenCL::Event::;

   @OpenCL::MappedBuffer::ISA  =
   @OpenCL::MappedImage::ISA   = OpenCL::Mapped::;
}

=head2 THE OpenCL PACKAGE

=over 4

=item $int = OpenCL::errno

The last error returned by a function - it's only valid after an error occured
and before calling another OpenCL function.

=item $str = OpenCL::err2str [$errval]

Converts an error value into a human readable string. If no error value is
given, then the last error will be used (as returned by OpenCL::errno).

The latest version of this module knows the error constants
listed in L<http://cvs.schmorp.de/OpenCL/errstr.h>.

=item $str = OpenCL::enum2str $enum

Converts most enum values (of parameter names, image format constants,
object types, addressing and filter modes, command types etc.) into a
human readable string. When confronted with some random integer it can be
very helpful to pass it through this function to maybe get some readable
string out of it.

The latest version of this module knows the enumaration constants
listed in L<http://cvs.schmorp.de/OpenCL/enumstr.h>.

=item @platforms = OpenCL::platforms

Returns all available OpenCL::Platform objects.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clGetPlatformIDs.html>

=item $ctx = OpenCL::context_from_type $properties, $type = OpenCL::DEVICE_TYPE_DEFAULT, $callback->($err, $pvt) = $print_stderr

Tries to create a context from a default device and platform type - never worked for me.
Consider using C<< $platform->context_from_type >> instead.

type: OpenCL::DEVICE_TYPE_DEFAULT, OpenCL::DEVICE_TYPE_CPU, OpenCL::DEVICE_TYPE_GPU,
OpenCL::DEVICE_TYPE_ACCELERATOR, OpenCL::DEVICE_TYPE_CUSTOM, OpenCL::DEVICE_TYPE_ALL.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clCreateContextFromType.html>

=item $ctx = OpenCL::context $properties, \@devices, $callback->($err, $pvt) = $print_stderr)

Create a new OpenCL::Context object using the given device object(s).
Consider using C<< $platform->context >> instead.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clCreateContext.html>

=item OpenCL::wait_for_events $wait_events...

Waits for all events to complete.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clWaitForEvents.html>

=item OpenCL::poll

Checks if there are any outstanding events (see L<EVENT SYSTEM>) and
invokes their callbacks.

=item $OpenCL::INTERRUPT

The L<Async::Interrupt> object used to signal asynchronous events (see
L<EVENT SYSTEM>).

=cut

our $INTERRUPT = new Async::Interrupt c_cb => [$POLL_FUNC, 0];

&_eq_initialise ($INTERRUPT->signal_func);

=item $OpenCL::WATCHER

The L<AnyEvent> watcher object used to watch for asynchronous events (see
L<EVENT SYSTEM>). This variable is C<undef> until L<AnyEvent> has been
loaded I<and> initialised (e.g. by calling C<AnyEvent::detect>).

=cut

our $WATCHER;

sub _init_anyevent {
   $INTERRUPT->block;
   $WATCHER = AE::io ($INTERRUPT->pipe_fileno, 0, sub { $INTERRUPT->handle });
}

if (defined $AnyEvent::MODEL) {
   _init_anyevent;
} else {
   push @AnyEvent::post_detect, \&_init_anyevent;
}

=back

=head2 THE OpenCL::Object CLASS

This is the base class for all objects in the OpenCL module. The only
method it implements is the C<id> method, which is only useful if you want
to interface to OpenCL on the C level.

=over 4

=item $iv = $obj->id

OpenCL objects are represented by pointers or integers on the C level. If
you want to interface to an OpenCL object directly on the C level, then
you need this value, which is returned by this method. You should use an
C<IV> type in your code and cast that to the correct type.

=cut

sub OpenCL::Object::id {
   ref $_[0] eq "SCALAR"
      ? ${ $_[0] }
      : $_[0][0]
}

=back

=head2 THE OpenCL::Platform CLASS

=over 4

=item @devices = $platform->devices ($type = OpenCL::DEVICE_TYPE_ALL)

Returns a list of matching OpenCL::Device objects.

=item $ctx = $platform->context_from_type ($properties, $type = OpenCL::DEVICE_TYPE_DEFAULT, $callback->($err, $pvt) = $print_stderr)

Tries to create a context. Never worked for me, and you need devices explicitly anyway.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clCreateContextFromType.html>

=item $ctx = $platform->context ($properties, \@devices, $callback->($err, $pvt) = $print_stderr)

Create a new OpenCL::Context object using the given device object(s)- a
OpenCL::CONTEXT_PLATFORM property is supplied automatically.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clCreateContext.html>

=item $packed_value = $platform->info ($name)

Calls C<clGetPlatformInfo> and returns the packed, raw value - for
strings, this will be the string (possibly including terminating \0), for
other values you probably need to use the correct C<unpack>.

It's best to avoid this method and use one of the following convenience
wrappers.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clGetPlatformInfo.html>

=item $platform->unload_compiler

Attempts to unload the compiler for this platform, for endless
profit. Does nothing on OpenCL 1.1.

L<http://www.khronos.org/registry/cl/sdk/1.2/docs/man/xhtml/clUnloadPlatformCompiler.html>

=for gengetinfo begin platform

=item $string = $platform->profile

Calls C<clGetPlatformInfo> with C<OpenCL::PLATFORM_PROFILE> and returns the result.

=item $string = $platform->version

Calls C<clGetPlatformInfo> with C<OpenCL::PLATFORM_VERSION> and returns the result.

=item $string = $platform->name

Calls C<clGetPlatformInfo> with C<OpenCL::PLATFORM_NAME> and returns the result.

=item $string = $platform->vendor

Calls C<clGetPlatformInfo> with C<OpenCL::PLATFORM_VENDOR> and returns the result.

=item $string = $platform->extensions

Calls C<clGetPlatformInfo> with C<OpenCL::PLATFORM_EXTENSIONS> and returns the result.

=for gengetinfo end platform

=back

=head2 THE OpenCL::Device CLASS

=over 4

=item $packed_value = $device->info ($name)

See C<< $platform->info >> for details.

type: OpenCL::DEVICE_TYPE_DEFAULT, OpenCL::DEVICE_TYPE_CPU,
OpenCL::DEVICE_TYPE_GPU, OpenCL::DEVICE_TYPE_ACCELERATOR,
OpenCL::DEVICE_TYPE_CUSTOM, OpenCL::DEVICE_TYPE_ALL.

fp_config: OpenCL::FP_DENORM, OpenCL::FP_INF_NAN, OpenCL::FP_ROUND_TO_NEAREST,
OpenCL::FP_ROUND_TO_ZERO, OpenCL::FP_ROUND_TO_INF, OpenCL::FP_FMA,
OpenCL::FP_SOFT_FLOAT, OpenCL::FP_CORRECTLY_ROUNDED_DIVIDE_SQRT.

mem_cache_type: OpenCL::NONE, OpenCL::READ_ONLY_CACHE, OpenCL::READ_WRITE_CACHE.

local_mem_type: OpenCL::LOCAL, OpenCL::GLOBAL.

exec_capabilities: OpenCL::EXEC_KERNEL, OpenCL::EXEC_NATIVE_KERNEL.

command_queue_properties: OpenCL::QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE,
OpenCL::QUEUE_PROFILING_ENABLE.

partition_properties: OpenCL::DEVICE_PARTITION_EQUALLY,
OpenCL::DEVICE_PARTITION_BY_COUNTS, OpenCL::DEVICE_PARTITION_BY_COUNTS_LIST_END,
OpenCL::DEVICE_PARTITION_BY_AFFINITY_DOMAIN.

affinity_domain: OpenCL::DEVICE_AFFINITY_DOMAIN_NUMA,
OpenCL::DEVICE_AFFINITY_DOMAIN_L4_CACHE, OpenCL::DEVICE_AFFINITY_DOMAIN_L3_CACHE,
OpenCL::DEVICE_AFFINITY_DOMAIN_L2_CACHE, OpenCL::DEVICE_AFFINITY_DOMAIN_L1_CACHE,
OpenCL::DEVICE_AFFINITY_DOMAIN_NEXT_PARTITIONABLE.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clGetDeviceInfo.html>

=item @devices = $device->sub_devices (\@properties)

Creates OpencL::SubDevice objects by partitioning an existing device.

L<http://www.khronos.org/registry/cl/sdk/1.2/docs/man/xhtml/clCreateSubDevices.html>

=for gengetinfo begin device

=item $device_type = $device->type

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_TYPE> and returns the result.

=item $uint = $device->vendor_id

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_VENDOR_ID> and returns the result.

=item $uint = $device->max_compute_units

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_MAX_COMPUTE_UNITS> and returns the result.

=item $uint = $device->max_work_item_dimensions

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_MAX_WORK_ITEM_DIMENSIONS> and returns the result.

=item $int = $device->max_work_group_size

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_MAX_WORK_GROUP_SIZE> and returns the result.

=item @ints = $device->max_work_item_sizes

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_MAX_WORK_ITEM_SIZES> and returns the result.

=item $uint = $device->preferred_vector_width_char

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_PREFERRED_VECTOR_WIDTH_CHAR> and returns the result.

=item $uint = $device->preferred_vector_width_short

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_PREFERRED_VECTOR_WIDTH_SHORT> and returns the result.

=item $uint = $device->preferred_vector_width_int

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_PREFERRED_VECTOR_WIDTH_INT> and returns the result.

=item $uint = $device->preferred_vector_width_long

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_PREFERRED_VECTOR_WIDTH_LONG> and returns the result.

=item $uint = $device->preferred_vector_width_float

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_PREFERRED_VECTOR_WIDTH_FLOAT> and returns the result.

=item $uint = $device->preferred_vector_width_double

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_PREFERRED_VECTOR_WIDTH_DOUBLE> and returns the result.

=item $uint = $device->max_clock_frequency

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_MAX_CLOCK_FREQUENCY> and returns the result.

=item $bitfield = $device->address_bits

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_ADDRESS_BITS> and returns the result.

=item $uint = $device->max_read_image_args

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_MAX_READ_IMAGE_ARGS> and returns the result.

=item $uint = $device->max_write_image_args

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_MAX_WRITE_IMAGE_ARGS> and returns the result.

=item $ulong = $device->max_mem_alloc_size

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_MAX_MEM_ALLOC_SIZE> and returns the result.

=item $int = $device->image2d_max_width

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_IMAGE2D_MAX_WIDTH> and returns the result.

=item $int = $device->image2d_max_height

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_IMAGE2D_MAX_HEIGHT> and returns the result.

=item $int = $device->image3d_max_width

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_IMAGE3D_MAX_WIDTH> and returns the result.

=item $int = $device->image3d_max_height

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_IMAGE3D_MAX_HEIGHT> and returns the result.

=item $int = $device->image3d_max_depth

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_IMAGE3D_MAX_DEPTH> and returns the result.

=item $uint = $device->image_support

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_IMAGE_SUPPORT> and returns the result.

=item $int = $device->max_parameter_size

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_MAX_PARAMETER_SIZE> and returns the result.

=item $uint = $device->max_samplers

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_MAX_SAMPLERS> and returns the result.

=item $uint = $device->mem_base_addr_align

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_MEM_BASE_ADDR_ALIGN> and returns the result.

=item $uint = $device->min_data_type_align_size

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_MIN_DATA_TYPE_ALIGN_SIZE> and returns the result.

=item $device_fp_config = $device->single_fp_config

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_SINGLE_FP_CONFIG> and returns the result.

=item $device_mem_cache_type = $device->global_mem_cache_type

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_GLOBAL_MEM_CACHE_TYPE> and returns the result.

=item $uint = $device->global_mem_cacheline_size

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_GLOBAL_MEM_CACHELINE_SIZE> and returns the result.

=item $ulong = $device->global_mem_cache_size

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_GLOBAL_MEM_CACHE_SIZE> and returns the result.

=item $ulong = $device->global_mem_size

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_GLOBAL_MEM_SIZE> and returns the result.

=item $ulong = $device->max_constant_buffer_size

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_MAX_CONSTANT_BUFFER_SIZE> and returns the result.

=item $uint = $device->max_constant_args

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_MAX_CONSTANT_ARGS> and returns the result.

=item $device_local_mem_type = $device->local_mem_type

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_LOCAL_MEM_TYPE> and returns the result.

=item $ulong = $device->local_mem_size

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_LOCAL_MEM_SIZE> and returns the result.

=item $boolean = $device->error_correction_support

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_ERROR_CORRECTION_SUPPORT> and returns the result.

=item $int = $device->profiling_timer_resolution

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_PROFILING_TIMER_RESOLUTION> and returns the result.

=item $boolean = $device->endian_little

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_ENDIAN_LITTLE> and returns the result.

=item $boolean = $device->available

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_AVAILABLE> and returns the result.

=item $boolean = $device->compiler_available

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_COMPILER_AVAILABLE> and returns the result.

=item $device_exec_capabilities = $device->execution_capabilities

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_EXECUTION_CAPABILITIES> and returns the result.

=item $command_queue_properties = $device->properties

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_QUEUE_PROPERTIES> and returns the result.

=item $ = $device->platform

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_PLATFORM> and returns the result.

=item $string = $device->name

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_NAME> and returns the result.

=item $string = $device->vendor

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_VENDOR> and returns the result.

=item $string = $device->driver_version

Calls C<clGetDeviceInfo> with C<OpenCL::DRIVER_VERSION> and returns the result.

=item $string = $device->profile

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_PROFILE> and returns the result.

=item $string = $device->version

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_VERSION> and returns the result.

=item $string = $device->extensions

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_EXTENSIONS> and returns the result.

=item $uint = $device->preferred_vector_width_half

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_PREFERRED_VECTOR_WIDTH_HALF> and returns the result.

=item $uint = $device->native_vector_width_char

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_NATIVE_VECTOR_WIDTH_CHAR> and returns the result.

=item $uint = $device->native_vector_width_short

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_NATIVE_VECTOR_WIDTH_SHORT> and returns the result.

=item $uint = $device->native_vector_width_int

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_NATIVE_VECTOR_WIDTH_INT> and returns the result.

=item $uint = $device->native_vector_width_long

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_NATIVE_VECTOR_WIDTH_LONG> and returns the result.

=item $uint = $device->native_vector_width_float

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_NATIVE_VECTOR_WIDTH_FLOAT> and returns the result.

=item $uint = $device->native_vector_width_double

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_NATIVE_VECTOR_WIDTH_DOUBLE> and returns the result.

=item $uint = $device->native_vector_width_half

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_NATIVE_VECTOR_WIDTH_HALF> and returns the result.

=item $device_fp_config = $device->double_fp_config

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_DOUBLE_FP_CONFIG> and returns the result.

=item $device_fp_config = $device->half_fp_config

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_HALF_FP_CONFIG> and returns the result.

=item $boolean = $device->host_unified_memory

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_HOST_UNIFIED_MEMORY> and returns the result.

=item $device = $device->parent_device_ext

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_PARENT_DEVICE_EXT> and returns the result.

=item @device_partition_property_exts = $device->partition_types_ext

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_PARTITION_TYPES_EXT> and returns the result.

=item @device_partition_property_exts = $device->affinity_domains_ext

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_AFFINITY_DOMAINS_EXT> and returns the result.

=item $uint = $device->reference_count_ext

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_REFERENCE_COUNT_EXT> and returns the result.

=item @device_partition_property_exts = $device->partition_style_ext

Calls C<clGetDeviceInfo> with C<OpenCL::DEVICE_PARTITION_STYLE_EXT> and returns the result.

=for gengetinfo end device

=back

=head2 THE OpenCL::Context CLASS

An OpenCL::Context is basically a container, or manager, for a number of
devices of a platform. It is used to create all sorts of secondary objects
such as buffers, queues, programs and so on.

All context creation functions and methods take a list of properties
(type-value pairs). All property values can be specified as integers -
some additionally support other types:

=over 4

=item OpenCL::CONTEXT_PLATFORM

Also accepts OpenCL::Platform objects.

=item OpenCL::GLX_DISPLAY_KHR

Also accepts C<undef>, in which case a deep and troubling hack is engaged
to find the current glx display (see L<GLX SUPPORT>).

=item OpenCL::GL_CONTEXT_KHR

Also accepts C<undef>, in which case a deep and troubling hack is engaged
to find the current glx context (see L<GLX SUPPORT>).

=back

=over 4

=item $prog = $ctx->build_program ($program, $options = "")

This convenience function tries to build the program on all devices in
the context. If the build fails, then the function will C<croak> with the
build log. Otherwise ti returns the program object.

The C<$program> can either be a C<OpenCL::Program> object or a string
containing the program. In the latter case, a program objetc will be
created automatically.

=cut

sub OpenCL::Context::build_program {
   my ($self, $prog, $options) = @_;

   $prog = $self->program_with_source ($prog)
      unless ref $prog;

   eval { $prog->build (undef, $options); 1 }
      or errno == BUILD_PROGRAM_FAILURE
      or errno == INVALID_BINARY # workaround nvidia bug
      or Carp::croak "OpenCL::Context->build_program: " . err2str;

   # we check status for all devices
   for my $dev ($self->devices) {
      $prog->build_status ($dev) == BUILD_SUCCESS
         or Carp::croak "Building OpenCL program for device '" . $dev->name . "' failed:\n"
                        . $prog->build_log ($dev);
   }

   $prog
}

=item $queue = $ctx->queue ($device, $properties)

Create a new OpenCL::Queue object from the context and the given device.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clCreateCommandQueue.html>

Example: create an out-of-order queue.

   $queue = $ctx->queue ($device, OpenCL::QUEUE_OUT_OF_ORDER_EXEC_MODE_ENABLE);

=item $ev = $ctx->user_event

Creates a new OpenCL::UserEvent object.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clCreateUserEvent.html>

=item $buf = $ctx->buffer ($flags, $len)

Creates a new OpenCL::Buffer (actually OpenCL::BufferObj) object with the
given flags and octet-size.

flags: OpenCL::MEM_READ_WRITE, OpenCL::MEM_WRITE_ONLY, OpenCL::MEM_READ_ONLY,
OpenCL::MEM_USE_HOST_PTR, OpenCL::MEM_ALLOC_HOST_PTR, OpenCL::MEM_COPY_HOST_PTR,
OpenCL::MEM_HOST_WRITE_ONLY, OpenCL::MEM_HOST_READ_ONLY, OpenCL::MEM_HOST_NO_ACCESS.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clCreateBuffer.html>

=item $buf = $ctx->buffer_sv ($flags, $data)

Creates a new OpenCL::Buffer (actually OpenCL::BufferObj) object and
initialise it with the given data values.

=item $img = $ctx->image ($self, $flags, $channel_order, $channel_type, $type, $width, $height, $depth = 0, $array_size = 0, $row_pitch = 0, $slice_pitch = 0, $num_mip_level = 0, $num_samples = 0, $*data = &PL_sv_undef)

Creates a new OpenCL::Image object and optionally initialises it with
the given data values.

channel_order: OpenCL::R, OpenCL::A, OpenCL::RG, OpenCL::RA, OpenCL::RGB,
OpenCL::RGBA, OpenCL::BGRA, OpenCL::ARGB, OpenCL::INTENSITY, OpenCL::LUMINANCE,
OpenCL::Rx, OpenCL::RGx, OpenCL::RGBx.

channel_type: OpenCL::SNORM_INT8, OpenCL::SNORM_INT16, OpenCL::UNORM_INT8,
OpenCL::UNORM_INT16, OpenCL::UNORM_SHORT_565, OpenCL::UNORM_SHORT_555,
OpenCL::UNORM_INT_101010, OpenCL::SIGNED_INT8, OpenCL::SIGNED_INT16,
OpenCL::SIGNED_INT32, OpenCL::UNSIGNED_INT8, OpenCL::UNSIGNED_INT16,
OpenCL::UNSIGNED_INT32, OpenCL::HALF_FLOAT, OpenCL::FLOAT.

type: OpenCL::MEM_OBJECT_BUFFER, OpenCL::MEM_OBJECT_IMAGE2D,
OpenCL::MEM_OBJECT_IMAGE3D, OpenCL::MEM_OBJECT_IMAGE2D_ARRAY,
OpenCL::MEM_OBJECT_IMAGE1D, OpenCL::MEM_OBJECT_IMAGE1D_ARRAY,
OpenCL::MEM_OBJECT_IMAGE1D_BUFFER.

L<http://www.khronos.org/registry/cl/sdk/1.2/docs/man/xhtml/clCreateImage.html>

=item $img = $ctx->image2d ($flags, $channel_order, $channel_type, $width, $height, $row_pitch = 0, $data = undef)

Creates a new OpenCL::Image2D object and optionally initialises it with
the given data values.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clCreateImage2D.html>

=item $img = $ctx->image3d ($flags, $channel_order, $channel_type, $width, $height, $depth, $row_pitch = 0, $slice_pitch = 0, $data = undef)

Creates a new OpenCL::Image3D object and optionally initialises it with
the given data values.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clCreateImage3D.html>

=item $buffer = $ctx->gl_buffer ($flags, $bufobj)

Creates a new OpenCL::Buffer (actually OpenCL::BufferObj) object that refers to the given
OpenGL buffer object.

flags: OpenCL::MEM_READ_WRITE, OpenCL::MEM_READ_ONLY, OpenCL::MEM_WRITE_ONLY.

http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clCreateFromGLBuffer.html

=item $img = $ctx->gl_texture ($flags, $target, $miplevel, $texture)

Creates a new OpenCL::Image object that refers to the given OpenGL
texture object or buffer.

target: GL_TEXTURE_1D, GL_TEXTURE_1D_ARRAY, GL_TEXTURE_BUFFER,
GL_TEXTURE_2D, GL_TEXTURE_2D_ARRAY, GL_TEXTURE_3D,
GL_TEXTURE_CUBE_MAP_POSITIVE_X, GL_TEXTURE_CUBE_MAP_POSITIVE_Y,
GL_TEXTURE_CUBE_MAP_POSITIVE_Z, GL_TEXTURE_CUBE_MAP_NEGATIVE_X,
GL_TEXTURE_CUBE_MAP_NEGATIVE_Y, GL_TEXTURE_CUBE_MAP_NEGATIVE_Z,
GL_TEXTURE_RECTANGLE/GL_TEXTURE_RECTANGLE_ARB.

http://www.khronos.org/registry/cl/sdk/1.2/docs/man/xhtml/clCreateFromGLTexture.html

=item $img = $ctx->gl_texture2d ($flags, $target, $miplevel, $texture)

Creates a new OpenCL::Image2D object that refers to the given OpenGL
2D texture object.

http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clCreateFromGLTexture2D.html

=item $img = $ctx->gl_texture3d ($flags, $target, $miplevel, $texture)

Creates a new OpenCL::Image3D object that refers to the given OpenGL
3D texture object.

http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clCreateFromGLTexture3D.html

=item $ctx->gl_renderbuffer ($flags, $renderbuffer)

Creates a new OpenCL::Image2D object that refers to the given OpenGL
render buffer.

http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clCreateFromGLRenderbuffer.html

=item @formats = $ctx->supported_image_formats ($flags, $image_type)

Returns a list of matching image formats - each format is an arrayref with
two values, $channel_order and $channel_type, in it.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clGetSupportedImageFormats.html>

=item $sampler = $ctx->sampler ($normalized_coords, $addressing_mode, $filter_mode)

Creates a new OpenCL::Sampler object.

addressing_mode: OpenCL::ADDRESS_NONE, OpenCL::ADDRESS_CLAMP_TO_EDGE,
OpenCL::ADDRESS_CLAMP, OpenCL::ADDRESS_REPEAT, OpenCL::ADDRESS_MIRRORED_REPEAT.

filter_mode: OpenCL::FILTER_NEAREST, OpenCL::FILTER_LINEAR.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clCreateSampler.html>

=item $program = $ctx->program_with_source ($string)

Creates a new OpenCL::Program object from the given source code.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clCreateProgramWithSource.html>

=item ($program, \@status) = $ctx->program_with_binary (\@devices, \@binaries)

Creates a new OpenCL::Program object from the given binaries.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clCreateProgramWithBinary.html>

Example: clone an existing program object that contains a successfully
compiled program, no matter how useless this is.

   my $clone = $ctx->program_with_binary ([$prog->devices], [$prog->binaries]);

=item $program = $ctx->program_with_built_in_kernels (\@devices, $kernel_names)

Creates a new OpenCL::Program object from the given built-in kernel names.

L<http://www.khronos.org/registry/cl/sdk/1.2/docs/man/xhtml/clCreateProgramWithBuiltInKernels.html>

=item $program = $ctx->link_program (\@devices, $options, \@programs, $cb->($program) = undef)

Links all (already compiled) program objects specified in C<@programs>
together and returns a new OpenCL::Program object with the result.

L<http://www.khronos.org/registry/cl/sdk/1.2/docs/man/xhtml/clLinkProgram.html>

=item $packed_value = $ctx->info ($name)

See C<< $platform->info >> for details.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clGetContextInfo.html>

=for gengetinfo begin context

=item $uint = $context->reference_count

Calls C<clGetContextInfo> with C<OpenCL::CONTEXT_REFERENCE_COUNT> and returns the result.

=item @devices = $context->devices

Calls C<clGetContextInfo> with C<OpenCL::CONTEXT_DEVICES> and returns the result.

=item @property_ints = $context->properties

Calls C<clGetContextInfo> with C<OpenCL::CONTEXT_PROPERTIES> and returns the result.

=item $uint = $context->num_devices

Calls C<clGetContextInfo> with C<OpenCL::CONTEXT_NUM_DEVICES> and returns the result.

=for gengetinfo end context

=back

=head2 THE OpenCL::Queue CLASS

An OpenCL::Queue represents an execution queue for OpenCL. You execute
requests by calling their respective method and waiting for it to complete
in some way.

Most methods that enqueue some request return an event object that can
be used to wait for completion (optionally using a callback), unless
the method is called in void context, in which case no event object is
created.

They also allow you to specify any number of other event objects that this
request has to wait for before it starts executing, by simply passing the
event objects as extra parameters to the enqueue methods. To simplify
program design, this module ignores any C<undef> values in the list of
events. This makes it possible to code operations such as this, without
having to put a valid event object into C<$event> first:

   $event = $queue->xxx (..., $event);

Queues execute in-order by default, without any parallelism, so in most
cases (i.e. you use only one queue) it's not necessary to wait for or
create event objects, althoguh an our of order queue is often a bit
faster.

=over 4

=item $ev = $queue->read_buffer ($buffer, $blocking, $offset, $len, $data, $wait_events...)

Reads data from buffer into the given string.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clEnqueueReadBuffer.html>

=item $ev = $queue->write_buffer ($buffer, $blocking, $offset, $data, $wait_events...)

Writes data to buffer from the given string.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clEnqueueWriteBuffer.html>

=item $ev = $queue->copy_buffer ($src, $dst, $src_offset, $dst_offset, $len, $wait_events...)

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clEnqueueCopyBuffer.html>

$eue->read_buffer_rect ($buf, cl_bool blocking, $buf_x, $buf_y, $buf_z, $host_x, $host_y, $host_z, $width, $height, $depth, $buf_row_pitch, $buf_slice_pitch, $host_row_pitch, $host_slice_pitch, $data, $wait_events...)

http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clEnqueueReadBufferRect.html

=item $ev = $queue->write_buffer_rect ($buf, $blocking, $buf_y, $host_x, $host_z, $height, $buf_row_pitch, $host_row_pitch, $data, $wait_events...)

http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clEnqueueWriteBufferRect.html

=item $ev = $queue->copy_buffer_to_image ($src_buffer, $dst_image, $src_offset, $dst_x, $dst_y, $dst_z, $width, $height, $depth, $wait_events...)

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clEnqueueCopyBufferToImage.html>

=item $ev = $queue->read_image ($src, $blocking, $x, $y, $z, $width, $height, $depth, $row_pitch, $slice_pitch, $data, $wait_events...)

C<$row_pitch> (and C<$slice_pitch>) can be C<0>, in which case the OpenCL
module uses the image width (and height) to supply default values.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clEnqueueReadImage.html>

=item $ev = $queue->write_image ($src, $blocking, $x, $y, $z, $width, $height, $depth, $row_pitch, $slice_pitch, $data, $wait_events...)

C<$row_pitch> (and C<$slice_pitch>) can be C<0>, in which case the OpenCL
module uses the image width (and height) to supply default values.
L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clEnqueueWriteImage.html>

=item $ev = $queue->copy_image ($src_image, $dst_image, $src_x, $src_y, $src_z, $dst_x, $dst_y, $dst_z, $width, $height, $depth, $wait_events...)

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clEnqueueCopyImage.html>

=item $ev = $queue->copy_image_to_buffer ($src_image, $dst_image, $src_x, $src_y, $src_z, $width, $height, $depth, $dst_offset, $wait_events...)

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clEnqueueCopyImageToBuffer.html>

=item $ev = $queue->copy_buffer_rect ($src, $dst, $src_x, $src_y, $src_z, $dst_x, $dst_y, $dst_z, $width, $height, $depth, $src_row_pitch, $src_slice_pitch, $dst_row_pitch, $dst_slice_pitch, $wait_event...)

Yeah.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clEnqueueCopyBufferToImage.html>.

=item $ev = $queue->fill_buffer ($mem, $pattern, $offset, $size, ...)

Fills the given buffer object with repeated applications of C<$pattern>,
starting at C<$offset> for C<$size> octets.

L<http://www.khronos.org/registry/cl/sdk/1.2/docs/man/xhtml/clEnqueueFillBuffer.html>

=item $ev = $queue->fill_image ($img, $r, $g, $b, $a, $x, $y, $z, $width, $height, $depth, ...)

Fills the given image area with the given rgba colour components. The
components are normally floating point values between C<0> and C<1>,
except when the image channel data type is a signe dor unsigned
unnormalised format, in which case the range is determined by the format.

L<http://www.khronos.org/registry/cl/sdk/1.2/docs/man/xhtml/clEnqueueFillImage.html>

=item $ev = $queue->task ($kernel, $wait_events...)

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clEnqueueTask.html>

=item $ev = $queue->nd_range_kernel ($kernel, \@global_work_offset, \@global_work_size, \@local_work_size, $wait_events...)

Enqueues a kernel execution.

\@global_work_size must be specified as a reference to an array of
integers specifying the work sizes (element counts).

\@global_work_offset must be either C<undef> (in which case all offsets
are C<0>), or a reference to an array of work offsets, with the same number
of elements as \@global_work_size.

\@local_work_size must be either C<undef> (in which case the
implementation is supposed to choose good local work sizes), or a
reference to an array of local work sizes, with the same number of
elements as \@global_work_size.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clEnqueueNDRangeKernel.html>

=item $ev = $queue->migrate_mem_objects (\@mem_objects, $flags, $wait_events...)

Migrates a number of OpenCL::Memory objects to or from the device.

flags: OpenCL::MIGRATE_MEM_OBJECT_HOST, OpenCL::MIGRATE_MEM_OBJECT_CONTENT_UNDEFINED

L<http://www.khronos.org/registry/cl/sdk/1.2/docs/man/xhtml/clEnqueueMigrateMemObjects.html>

=item $ev = $queue->acquire_gl_objects ([object, ...], $wait_events...)

Enqueues a list (an array-ref of OpenCL::Memory objects) to be acquired
for subsequent OpenCL usage.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clEnqueueAcquireGLObjects.html>

=item $ev = $queue->release_gl_objects ([object, ...], $wait_events...)

Enqueues a list (an array-ref of OpenCL::Memory objects) to be released
for subsequent OpenGL usage.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clEnqueueReleaseGLObjects.html>

=item $ev = $queue->wait_for_events ($wait_events...)

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clEnqueueWaitForEvents.html>

=item $ev = $queue->marker ($wait_events...)

L<http://www.khronos.org/registry/cl/sdk/1.2/docs/man/xhtml/clEnqueueMarkerWithWaitList.html>

=item $ev = $queue->barrier ($wait_events...)

L<http://www.khronos.org/registry/cl/sdk/1.2/docs/man/xhtml/clEnqueueBarrierWithWaitList.html>

=item $queue->flush

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clFlush.html>

=item $queue->finish

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clFinish.html>

=item $packed_value = $queue->info ($name)

See C<< $platform->info >> for details.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clGetCommandQueueInfo.html>

=for gengetinfo begin command_queue

=item $ctx = $command_queue->context

Calls C<clGetCommandQueueInfo> with C<OpenCL::QUEUE_CONTEXT> and returns the result.

=item $device = $command_queue->device

Calls C<clGetCommandQueueInfo> with C<OpenCL::QUEUE_DEVICE> and returns the result.

=item $uint = $command_queue->reference_count

Calls C<clGetCommandQueueInfo> with C<OpenCL::QUEUE_REFERENCE_COUNT> and returns the result.

=item $command_queue_properties = $command_queue->properties

Calls C<clGetCommandQueueInfo> with C<OpenCL::QUEUE_PROPERTIES> and returns the result.

=for gengetinfo end command_queue

=back

=head3 MEMORY MAPPED BUFFERS

OpenCL allows you to map buffers and images to host memory (read: perl
scalars). This is done much like reading or copying a buffer, by enqueuing
a map or unmap operation on the command queue.

The map operations return an C<OpenCL::Mapped> object - see L<THE
OpenCL::Mapped CLASS> section for details on what to do with these
objects.

The object will be unmapped automatically when the mapped object is
destroyed (you can use a barrier to make sure the unmap has finished,
before using the buffer in a kernel), but you can also enqueue an unmap
operation manually.

=over 4

=item $mapped_buffer = $queue->map_buffer ($buf, $blocking=1, $map_flags=OpenCL::MAP_READ|OpenCL::MAP_WRITE, $offset=0, $size=undef, $wait_events...)

Maps the given buffer into host memory and returns an
C<OpenCL::MappedBuffer> object. If C<$size> is specified as undef, then
the map will extend to the end of the buffer.

map_flags: OpenCL::MAP_READ, OpenCL::MAP_WRITE, OpenCL::MAP_WRITE_INVALIDATE_REGION.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clEnqueueMapBuffer.html>

Example: map the buffer $buf fully and replace the first 4 bytes by "abcd", then unmap.

   {
     my $mapped = $queue->map_buffer ($buf, 1, OpenCL::MAP_WRITE);
     substr $$mapped, 0, 4, "abcd";
   } # asynchronously unmap because $mapped is destroyed

=item $mapped_image = $queue->map_image ($img, $blocking=1, $map_flags=OpenCL::MAP_READ|OpenCL::MAP_WRITE, $x=0, $y=0, $z=0, $width=undef, $height=undef, $depth=undef, $wait_events...)

Maps the given image area into host memory and return an
C<OpenCL::MappedImage> object.

If any of C<$width>, C<$height> and/or C<$depth> are C<undef> then they
will be replaced by the maximum possible value.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clEnqueueMapImage.html>

Example: map an image (with OpenCL::UNSIGNED_INT8 channel type) and set
the first channel of the leftmost column to 5, then explicitly unmap
it. You are not necessarily meant to do it this way, this example just
shows you the accessors to use :)

   my $mapped = $queue->map_image ($image, 1, OpenCL::MAP_WRITE);

   $mapped->write ($_ * $mapped->row_pitch, pack "C", 5)
      for 0 .. $mapped->height - 1;

   $mapped->unmap;.
   $mapped->wait; # only needed for out of order queues normally

=item $ev = $queue->unmap ($mapped, $wait_events...)

Unmaps the data from host memory. You must not call any methods that
modify the data, or modify the data scalar directly, after calling this
method.

The mapped event object will always be passed as part of the
$wait_events. The mapped event object will be replaced by the new event
object that this request creates.

=back

=head2 THE OpenCL::Memory CLASS

This the superclass of all memory objects - OpenCL::Buffer, OpenCL::Image,
OpenCL::Image2D and OpenCL::Image3D.

=over 4

=item $packed_value = $memory->info ($name)

See C<< $platform->info >> for details.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clGetMemObjectInfo.html>

=item $memory->destructor_callback ($cb->())

Sets a callback that will be invoked after the memory object is destructed.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clSetMemObjectDestructorCallback.html>

=for gengetinfo begin mem

=item $mem_object_type = $mem->type

Calls C<clGetMemObjectInfo> with C<OpenCL::MEM_TYPE> and returns the result.

=item $mem_flags = $mem->flags

Calls C<clGetMemObjectInfo> with C<OpenCL::MEM_FLAGS> and returns the result.

=item $int = $mem->size

Calls C<clGetMemObjectInfo> with C<OpenCL::MEM_SIZE> and returns the result.

=item $ptr_value = $mem->host_ptr

Calls C<clGetMemObjectInfo> with C<OpenCL::MEM_HOST_PTR> and returns the result.

=item $uint = $mem->map_count

Calls C<clGetMemObjectInfo> with C<OpenCL::MEM_MAP_COUNT> and returns the result.

=item $uint = $mem->reference_count

Calls C<clGetMemObjectInfo> with C<OpenCL::MEM_REFERENCE_COUNT> and returns the result.

=item $ctx = $mem->context

Calls C<clGetMemObjectInfo> with C<OpenCL::MEM_CONTEXT> and returns the result.

=item $mem = $mem->associated_memobject

Calls C<clGetMemObjectInfo> with C<OpenCL::MEM_ASSOCIATED_MEMOBJECT> and returns the result.

=item $int = $mem->offset

Calls C<clGetMemObjectInfo> with C<OpenCL::MEM_OFFSET> and returns the result.

=for gengetinfo end mem

=item ($type, $name) = $mem->gl_object_info

Returns the OpenGL object type (e.g. OpenCL::GL_OBJECT_TEXTURE2D) and the
object "name" (e.g. the texture name) used to create this memory object.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clGetGLObjectInfo.html>

=back

=head2 THE OpenCL::Buffer CLASS

This is a subclass of OpenCL::Memory, and the superclass of
OpenCL::BufferObj. Its purpose is simply to distinguish between buffers
and sub-buffers.

=head2 THE OpenCL::BufferObj CLASS

This is a subclass of OpenCL::Buffer and thus OpenCL::Memory. It exists
because one cna create sub buffers of OpenLC::BufferObj objects, but not
sub buffers from these sub buffers.

=over 4

=item $subbuf = $buf_obj->sub_buffer_region ($flags, $origin, $size)

Creates an OpenCL::Buffer objects from this buffer and returns it. The
C<buffer_create_type> is assumed to be C<OpenCL::BUFFER_CREATE_TYPE_REGION>.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clCreateSubBuffer.html>

=back

=head2 THE OpenCL::Image CLASS

This is the superclass of all image objects - OpenCL::Image1D,
OpenCL::Image1DArray, OpenCL::Image1DBuffer, OpenCL::Image2D,
OpenCL::Image2DArray and OpenCL::Image3D.

=over 4

=item $packed_value = $image->image_info ($name)

See C<< $platform->info >> for details.

The reason this method is not called C<info> is that there already is an
C<< ->info >> method inherited from C<OpenCL::Memory>.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clGetImageInfo.html>

=item ($channel_order, $channel_data_type) = $image->format

Returns the channel order and type used to create the image by calling
C<clGetImageInfo> with C<OpenCL::IMAGE_FORMAT>.

=for gengetinfo begin image

=item $int = $image->element_size

Calls C<clGetImageInfo> with C<OpenCL::IMAGE_ELEMENT_SIZE> and returns the result.

=item $int = $image->row_pitch

Calls C<clGetImageInfo> with C<OpenCL::IMAGE_ROW_PITCH> and returns the result.

=item $int = $image->slice_pitch

Calls C<clGetImageInfo> with C<OpenCL::IMAGE_SLICE_PITCH> and returns the result.

=item $int = $image->width

Calls C<clGetImageInfo> with C<OpenCL::IMAGE_WIDTH> and returns the result.

=item $int = $image->height

Calls C<clGetImageInfo> with C<OpenCL::IMAGE_HEIGHT> and returns the result.

=item $int = $image->depth

Calls C<clGetImageInfo> with C<OpenCL::IMAGE_DEPTH> and returns the result.

=for gengetinfo end image

=for gengetinfo begin gl_texture

=item $GLenum = $gl_texture->target

Calls C<clGetGLTextureInfo> with C<OpenCL::GL_TEXTURE_TARGET> and returns the result.

=item $GLint = $gl_texture->gl_mipmap_level

Calls C<clGetGLTextureInfo> with C<OpenCL::GL_MIPMAP_LEVEL> and returns the result.

=for gengetinfo end gl_texture

=back

=head2 THE OpenCL::Sampler CLASS

=over 4

=item $packed_value = $sampler->info ($name)

See C<< $platform->info >> for details.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clGetSamplerInfo.html>

=for gengetinfo begin sampler

=item $uint = $sampler->reference_count

Calls C<clGetSamplerInfo> with C<OpenCL::SAMPLER_REFERENCE_COUNT> and returns the result.

=item $ctx = $sampler->context

Calls C<clGetSamplerInfo> with C<OpenCL::SAMPLER_CONTEXT> and returns the result.

=item $addressing_mode = $sampler->normalized_coords

Calls C<clGetSamplerInfo> with C<OpenCL::SAMPLER_NORMALIZED_COORDS> and returns the result.

=item $filter_mode = $sampler->addressing_mode

Calls C<clGetSamplerInfo> with C<OpenCL::SAMPLER_ADDRESSING_MODE> and returns the result.

=item $boolean = $sampler->filter_mode

Calls C<clGetSamplerInfo> with C<OpenCL::SAMPLER_FILTER_MODE> and returns the result.

=for gengetinfo end sampler

=back

=head2 THE OpenCL::Program CLASS

=over 4

=item $program->build (\@devices = undef, $options = "", $cb->($program) = undef)

Tries to build the program with the given options. See also the
C<$ctx->build> convenience function.

If a callback is specified, then it will be called when compilation is
finished. Note that many OpenCL implementations block your program while
compiling whether you use a callback or not. See C<build_async> if you
want to make sure the build is done in the background.

Note that some OpenCL implementations act up badly, and don't call the
callback in some error cases (but call it in others). This implementation
assumes the callback will always be called, and leaks memory if this is
not so. So best make sure you don't pass in invalid values.

Some implementations fail with C<OpenCL::INVALID_BINARY> when the
compilation state is successful but some later stage fails.

options: C<-D name>, C<-D name=definition>, C<-I dir>,
C<-cl-single-precision-constant>, C<-cl-denorms-are-zero>,
C<-cl-fp32-correctly-rounded-divide-sqrt>, C<-cl-opt-disable>,
C<-cl-mad-enable>, C<-cl-no-signed-zeros>, C<-cl-unsafe-math-optimizations>,
C<-cl-finite-math-only>, C<-cl-fast-relaxed-math>,
C<-w>, C<-Werror>, C<-cl-std=CL1.1/CL1.2>, C<-cl-kernel-arg-info>,
C<-create-library>, C<-enable-link-options>.

build_status: OpenCL::BUILD_SUCCESS, OpenCL::BUILD_NONE,
OpenCL::BUILD_ERROR, OpenCL::BUILD_IN_PROGRESS.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clBuildProgram.html>

=item $program->build_async (\@devices = undef, $options = "", $cb->($program) = undef)

Similar to C<< ->build >>, except it starts a thread, and never fails (you
need to check the compilation status form the callback, or by polling).

=item $program->compile (\@devices = undef, $options = "", \%headers = undef, $cb->($program) = undef)

Compiles the given program for the given devices (or all devices if
undef). If C<$headers> is given, it must be a hashref with include name =>
OpenCL::Program pairs.

L<http://www.khronos.org/registry/cl/sdk/1.2/docs/man/xhtml/clCompileProgram.html>

=item $packed_value = $program->build_info ($device, $name)

Similar to C<< $platform->info >>, but returns build info for a previous
build attempt for the given device.

binary_type: OpenCL::PROGRAM_BINARY_TYPE_NONE,
OpenCL::PROGRAM_BINARY_TYPE_COMPILED_OBJECT,
OpenCL::PROGRAM_BINARY_TYPE_LIBRARY,
OpenCL::PROGRAM_BINARY_TYPE_EXECUTABLE.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clGetBuildInfo.html>

=item $kernel = $program->kernel ($function_name)

Creates an OpenCL::Kernel object out of the named C<__kernel> function in
the program.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clCreateKernel.html>

=item @kernels = $program->kernels_in_program

Returns all kernels successfully compiled for all devices in program.

http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clCreateKernelsInProgram.html

=for gengetinfo begin program_build

=item $build_status = $program->build_status ($device)

Calls C<clGetProgramBuildInfo> with C<OpenCL::PROGRAM_BUILD_STATUS> and returns the result.

=item $string = $program->build_options ($device)

Calls C<clGetProgramBuildInfo> with C<OpenCL::PROGRAM_BUILD_OPTIONS> and returns the result.

=item $string = $program->build_log ($device)

Calls C<clGetProgramBuildInfo> with C<OpenCL::PROGRAM_BUILD_LOG> and returns the result.

=item $binary_type = $program->binary_type ($device)

Calls C<clGetProgramBuildInfo> with C<OpenCL::PROGRAM_BINARY_TYPE> and returns the result.

=for gengetinfo end program_build

=item $packed_value = $program->info ($name)

See C<< $platform->info >> for details.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clGetProgramInfo.html>

=for gengetinfo begin program

=item $uint = $program->reference_count

Calls C<clGetProgramInfo> with C<OpenCL::PROGRAM_REFERENCE_COUNT> and returns the result.

=item $ctx = $program->context

Calls C<clGetProgramInfo> with C<OpenCL::PROGRAM_CONTEXT> and returns the result.

=item $uint = $program->num_devices

Calls C<clGetProgramInfo> with C<OpenCL::PROGRAM_NUM_DEVICES> and returns the result.

=item @devices = $program->devices

Calls C<clGetProgramInfo> with C<OpenCL::PROGRAM_DEVICES> and returns the result.

=item $string = $program->source

Calls C<clGetProgramInfo> with C<OpenCL::PROGRAM_SOURCE> and returns the result.

=item @ints = $program->binary_sizes

Calls C<clGetProgramInfo> with C<OpenCL::PROGRAM_BINARY_SIZES> and returns the result.

=for gengetinfo end program

=item @blobs = $program->binaries

Returns a string for the compiled binary for every device associated with
the program, empty strings indicate missing programs, and an empty result
means no program binaries are available.

These "binaries" are often, in fact, informative low-level assembly
sources.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clGetProgramInfo.html>

=back

=head2 THE OpenCL::Kernel CLASS

=over 4

=item $packed_value = $kernel->info ($name)

See C<< $platform->info >> for details.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clGetKernelInfo.html>

=for gengetinfo begin kernel

=item $string = $kernel->function_name

Calls C<clGetKernelInfo> with C<OpenCL::KERNEL_FUNCTION_NAME> and returns the result.

=item $uint = $kernel->num_args

Calls C<clGetKernelInfo> with C<OpenCL::KERNEL_NUM_ARGS> and returns the result.

=item $uint = $kernel->reference_count

Calls C<clGetKernelInfo> with C<OpenCL::KERNEL_REFERENCE_COUNT> and returns the result.

=item $ctx = $kernel->context

Calls C<clGetKernelInfo> with C<OpenCL::KERNEL_CONTEXT> and returns the result.

=item $program = $kernel->program

Calls C<clGetKernelInfo> with C<OpenCL::KERNEL_PROGRAM> and returns the result.

=for gengetinfo end kernel

=item $packed_value = $kernel->work_group_info ($device, $name)

See C<< $platform->info >> for details.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clGetKernelWorkGroupInfo.html>

=for gengetinfo begin kernel_work_group

=item $int = $kernel->work_group_size ($device)

Calls C<clGetKernelWorkGroupInfo> with C<OpenCL::KERNEL_WORK_GROUP_SIZE> and returns the result.

=item @ints = $kernel->compile_work_group_size ($device)

Calls C<clGetKernelWorkGroupInfo> with C<OpenCL::KERNEL_COMPILE_WORK_GROUP_SIZE> and returns the result.

=item $ulong = $kernel->local_mem_size ($device)

Calls C<clGetKernelWorkGroupInfo> with C<OpenCL::KERNEL_LOCAL_MEM_SIZE> and returns the result.

=item $int = $kernel->preferred_work_group_size_multiple ($device)

Calls C<clGetKernelWorkGroupInfo> with C<OpenCL::KERNEL_PREFERRED_WORK_GROUP_SIZE_MULTIPLE> and returns the result.

=item $ulong = $kernel->private_mem_size ($device)

Calls C<clGetKernelWorkGroupInfo> with C<OpenCL::KERNEL_PRIVATE_MEM_SIZE> and returns the result.

=for gengetinfo end kernel_work_group

=item $packed_value = $kernel->arg_info ($idx, $name)

See C<< $platform->info >> for details.

L<http://www.khronos.org/registry/cl/sdk/1.2/docs/man/xhtml/clGetKernelArgInfo.html>

=for gengetinfo begin kernel_arg

=item $kernel_arg_address_qualifier = $kernel->arg_address_qualifier ($idx)

Calls C<clGetKernelArgInfo> with C<OpenCL::KERNEL_ARG_ADDRESS_QUALIFIER> and returns the result.

=item $kernel_arg_access_qualifier = $kernel->arg_access_qualifier ($idx)

Calls C<clGetKernelArgInfo> with C<OpenCL::KERNEL_ARG_ACCESS_QUALIFIER> and returns the result.

=item $string = $kernel->arg_type_name ($idx)

Calls C<clGetKernelArgInfo> with C<OpenCL::KERNEL_ARG_TYPE_NAME> and returns the result.

=item $kernel_arg_type_qualifier = $kernel->arg_type_qualifier ($idx)

Calls C<clGetKernelArgInfo> with C<OpenCL::KERNEL_ARG_TYPE_QUALIFIER> and returns the result.

=item $string = $kernel->arg_name ($idx)

Calls C<clGetKernelArgInfo> with C<OpenCL::KERNEL_ARG_NAME> and returns the result.

=for gengetinfo end kernel_arg

=item $kernel->setf ($format, ...)

Sets the arguments of a kernel. Since OpenCL 1.1 doesn't have a generic
way to set arguments (and with OpenCL 1.2 it might be rather slow), you
need to specify a format argument, much as with C<printf>, to tell OpenCL
what type of argument it is.

The format arguments are single letters:

   c   char
   C   unsigned char
   s   short
   S   unsigned short
   i   int
   I   unsigned int
   l   long
   L   unsigned long

   h   half float (0..65535)
   f   float
   d   double

   z   local (octet size)

   m   memory object (buffer or image)
   a   sampler
   e   event

Space characters in the format string are ignored.

Example: set the arguments for a kernel that expects an int, two floats, a buffer and an image.

   $kernel->setf ("i ff mm", 5, 0.5, 3, $buffer, $image);

=item $kernel->set_TYPE    ($index, $value)

=item $kernel->set_char    ($index, $value)

=item $kernel->set_uchar   ($index, $value)

=item $kernel->set_short   ($index, $value)

=item $kernel->set_ushort  ($index, $value)

=item $kernel->set_int     ($index, $value)

=item $kernel->set_uint    ($index, $value)

=item $kernel->set_long    ($index, $value)

=item $kernel->set_ulong   ($index, $value)

=item $kernel->set_half    ($index, $value)

=item $kernel->set_float   ($index, $value)

=item $kernel->set_double  ($index, $value)
                           
=item $kernel->set_memory  ($index, $value)
                           
=item $kernel->set_buffer  ($index, $value)

=item $kernel->set_image   ($index, $value)

=item $kernel->set_sampler ($index, $value)

=item $kernel->set_local   ($index, $value)

=item $kernel->set_event   ($index, $value)

This is a family of methods to set the kernel argument with the number
C<$index> to the give C<$value>.

Chars and integers (including the half type) are specified as integers,
float and double as floating point values, memory/buffer/image must be
an object of that type or C<undef>, local-memory arguments are set by
specifying the size, and sampler and event must be objects of that type.

Note that C<set_memory> works for all memory objects (all types of buffers
and images) - the main purpose of the more specific C<set_TYPE> functions
is type checking.

Setting an argument for a kernel does NOT keep a reference to the object -
for example, if you set an argument to some image object, free the image,
and call the kernel, you will run into undefined behaviour.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clSetKernelArg.html>

=back

=head2 THE OpenCL::Event CLASS

This is the superclass for all event objects (including OpenCL::UserEvent
objects).

=over 4

=item $ev->wait

Waits for the event to complete.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clWaitForEvents.html>

=item $ev->cb ($exec_callback_type, $callback->($event, $event_command_exec_status))

Adds a callback to the callback stack for the given event type. There is
no way to remove a callback again.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clSetEventCallback.html>

=item $packed_value = $ev->info ($name)

See C<< $platform->info >> for details.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clGetEventInfo.html>

=for gengetinfo begin event

=item $queue = $event->command_queue

Calls C<clGetEventInfo> with C<OpenCL::EVENT_COMMAND_QUEUE> and returns the result.

=item $command_type = $event->command_type

Calls C<clGetEventInfo> with C<OpenCL::EVENT_COMMAND_TYPE> and returns the result.

=item $uint = $event->reference_count

Calls C<clGetEventInfo> with C<OpenCL::EVENT_REFERENCE_COUNT> and returns the result.

=item $uint = $event->command_execution_status

Calls C<clGetEventInfo> with C<OpenCL::EVENT_COMMAND_EXECUTION_STATUS> and returns the result.

=item $ctx = $event->context

Calls C<clGetEventInfo> with C<OpenCL::EVENT_CONTEXT> and returns the result.

=for gengetinfo end event

=item $packed_value = $ev->profiling_info ($name)

See C<< $platform->info >> for details.

The reason this method is not called C<info> is that there already is an
C<< ->info >> method.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clGetProfilingInfo.html>

=for gengetinfo begin profiling

=item $ulong = $event->profiling_command_queued

Calls C<clGetEventProfilingInfo> with C<OpenCL::PROFILING_COMMAND_QUEUED> and returns the result.

=item $ulong = $event->profiling_command_submit

Calls C<clGetEventProfilingInfo> with C<OpenCL::PROFILING_COMMAND_SUBMIT> and returns the result.

=item $ulong = $event->profiling_command_start

Calls C<clGetEventProfilingInfo> with C<OpenCL::PROFILING_COMMAND_START> and returns the result.

=item $ulong = $event->profiling_command_end

Calls C<clGetEventProfilingInfo> with C<OpenCL::PROFILING_COMMAND_END> and returns the result.

=for gengetinfo end profiling

=back

=head2 THE OpenCL::UserEvent CLASS

This is a subclass of OpenCL::Event.

=over 4

=item $ev->set_status ($execution_status)

Sets the execution status of the user event. Can only be called once,
either with OpenCL::COMPLETE or a negative number as status.

execution_status: OpenCL::COMPLETE or a negative integer.

L<http://www.khronos.org/registry/cl/sdk/1.1/docs/man/xhtml/clSetUserEventStatus.html>

=back

=head2 THE OpenCL::Mapped CLASS

This class represents objects mapped into host memory. They are
represented by a blessed string scalar. The string data is the mapped
memory area, that is, if you read or write it, then the mapped object is
accessed directly.

You must only ever use operations that modify the string in-place - for
example, a C<substr> that doesn't change the length, or maybe a regex that
doesn't change the length. Any other operation might cause the data to be
copied.

When the object is destroyed it will enqueue an implicit unmap operation
on the queue that was used to create it.

Keep in mind that you I<need> to unmap (or destroy) mapped objects before
OpenCL sees the changes, even if some implementations don't need this
sometimes.

Example, replace the first two floats in the mapped buffer by 1 and 2.

   my $mapped = $queue->map_buffer ($buf, ...
   $mapped->event->wait; # make sure it's there

   # now replace first 8 bytes by new data, which is exactly 8 bytes long
   # we blindly assume device endianness to equal host endianness
   # (and of course, we assume iee 754 single precision floats :)
   substr $$mapped, 0, 8, pack "f*", 1, 2;

=over 4

=item $ev = $mapped->unmap ($wait_events...)

Unmaps the mapped memory object, using the queue originally used to create
it, quite similarly to C<< $queue->unmap ($mapped, ...) >>.

=item $bool = $mapped->mapped

Returns whether the object is still mapped - true before an C<unmap> is
enqueued, false afterwards.

=item $ev = $mapped->event

Return the event object associated with the mapped object. Initially, this
will be the event object created when mapping the object, and after an
unmap, this will be the event object that the unmap operation created.

=item $mapped->wait

Same as C<< $mapped->event->wait >> - makes sure no operations on this
mapped object are outstanding.

=item $bytes = $mapped->size

Returns the size of the mapped area, in bytes. Same as C<length $$mapped>.

=item $ptr = $mapped->ptr

Returns the raw memory address of the mapped area.

=item $mapped->set ($offset, $data)

Replaces the data at the given C<$offset> in the memory area by the new
C<$data>. This method is safer than direct manipulation of C<$mapped>
because it does bounds-checking, but also slower.

=item $data = $mapped->get ($offset, $length)

Returns (without copying) a scalar representing the data at the given
C<$offset> and C<$length> in the mapped memory area. This is the same as
the following substr, except much slower;

   $data = substr $$mapped, $offset, $length

=cut

sub OpenCL::Mapped::get {
   substr ${$_[0]}, $_[1], $_[2]
}

=back

=head2 THE OpenCL::MappedBuffer CLASS

This is a subclass of OpenCL::Mapped, representing mapped buffers.

=head2 THE OpenCL::MappedImage CLASS

This is a subclass of OpenCL::Mapped, representing mapped images.

=over 4

=item $pixels = $mapped->width

=item $pixels = $mapped->height

=item $pixels = $mapped->depth

Return the width/height/depth of the mapped image region, in pixels.

=item $bytes = $mapped->row_pitch

=item $bytes = $mapped->slice_pitch

Return the row or slice pitch of the image that has been mapped.

=item $bytes = $mapped->element_size

Return the size of a single pixel.

=item $data = $mapped->get_row ($count, $x=0, $y=0, $z=0)

Return C<$count> pixels from the given coordinates. The pixel data must
be completely contained within a single row.

If C<$count> is C<undef>, then all the remaining pixels in that row are
returned.

=item $mapped->set_row ($data, $x=0, $y=0, $z=0)

Write the given pixel data at the given coordinate. The pixel data must
be completely contained within a single row.

=back

=cut

1;

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

