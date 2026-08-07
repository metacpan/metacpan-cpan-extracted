use v5.36;
use Carp  qw[croak];
use Affix qw[Int UInt32 Pointer Void Array UInt64 Float typedef Struct affix sizeof];
use SDL3  qw[:all];
$|++;

# This demo creates a GPU Device, claims the window, and executes a render pass
# to clear the screen to a pulsing color. This proves the entire swapchain and
# command submission pipeline is working without needing to compile complex
# SPIR-V shaders yet.
#
# Controls:
#  - Alt-F4 to close the window?
#
SDL_Init(SDL_INIT_VIDEO) || die 'Init Failed: ' . SDL_GetError();
my $win = SDL_CreateWindow( 'SDL3 GPU Demo', 800, 600, SDL_WINDOW_RESIZABLE );
my $gpu = SDL_CreateGPUDevice( SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPU_SHADERFORMAT_MSL | SDL_GPU_SHADERFORMAT_DXIL, 1, undef );
$gpu // die 'GPU Init Failed';
SDL_ClaimWindowForGPUDevice( $gpu, $win ) || die 'Claim Failed';
#
my $event_ptr = Affix::malloc(128);
my $running   = 1;

# Pointers for Swapchain acquisition
my $ptr_tex = Affix::calloc( 1, sizeof( Pointer [Void] ) );
my $ptr_w   = Affix::calloc( 1, sizeof(UInt32) );
my $ptr_h   = Affix::calloc( 1, sizeof(UInt32) );
#
say 'GPU Initialized. Rendering...';

# Helper struct to peek into the memory returned by AcquireGPUSwapchainTexture
typedef GPUTexturePtr_t => Struct [ value => Pointer [Void] ];
while ($running) {
    $running = Affix::cast( $event_ptr, SDL_CommonEvent )->{type} != SDL_EVENT_QUIT while SDL_PollEvent($event_ptr);
    my $cmd = SDL_AcquireGPUCommandBuffer($gpu);
    next unless $cmd;
    if ( SDL_AcquireGPUSwapchainTexture( $cmd, $win, $ptr_tex, $ptr_w, $ptr_h ) ) {

        # Get Texture Handle
        # Dereference the handle using the helper struct defined above
        # This reads the actual pointer value out of the $ptr_tex buffer
        my $tex = Affix::cast( $ptr_tex, GPUTexturePtr_t() )->{value};

        #my $tex = $$ptr_tex;
        # If SDL gives us a NULL handle (during resizes, at startup before the swapchain is built,
        # or really any time the GPU driver isn't ready to give you an image) we just skip this frame
        if ($tex) {

            # Color fade
            my $t = SDL_GetTicks() / 1000.0;
            my $r = ( sin($t) + 1.0 ) / 2.0;
            my $g = ( cos( $t * 0.7 ) + 1.0 ) / 2.0;
            my $b = ( sin( $t * 1.3 ) + 1.0 ) / 2.0;

            # Define pass config (clean HV*)
            # Affix will:
            #   1. Allocate aligned memory in the Arena
            #   2. Fill space with NULLs just in case (for now...)
            #   3. Populate 'texture', 'clear_color', etc.
            #   4. Pass it to C
            # Note: We wrap in [ ... ] because SDL expects an array of structs
            my $targets = [
                {   texture              => $tex,
                    mip_level            => 0,
                    layer_or_depth_plane => 0,
                    clear_color          => { r => $r, g => $g, b => $b, a => 1.0 },
                    load_op              => SDL_GPU_LOADOP_CLEAR,
                    store_op             => SDL_GPU_STOREOP_STORE,
                    cycle                => 0
                }
            ];

            # Submit render pass
            my $pass = SDL_BeginGPURenderPass( $cmd, $targets, 1, undef );
            SDL_EndGPURenderPass($pass) if $pass;
        }
    }
    SDL_SubmitGPUCommandBuffer($cmd);
}
SDL_ReleaseWindowFromGPUDevice( $gpu, $win );
SDL_DestroyGPUDevice($gpu);
SDL_DestroyWindow($win);
SDL_Quit();
