import commonjs from 'rollup-plugin-commonjs';
import resolve from 'rollup-plugin-node-resolve';
import {terser} from 'rollup-plugin-terser';

// The html plugin generates a file that M::P::Webpack reads to generate the
// correct output when calling <%= asset 'example.js' %> and
// <%= asset 'example.css' %>
import html from 'rollup-plugin-bundle-html';

// This example app use https://svelte.dev/, so we need to load that plugin
import svelte from 'rollup-plugin-svelte';

// The output file need to contain a hash for M::P::Webpack to find it
const dest = process.env.WEBPACK_OUT_DIR || 'public/asset';
const production = !process.env.ROLLUP_WATCH;
function outPath(fn) {
  const filename = production ? fn : fn.replace(/\[hash\]/, 'development');
  return [dest, filename].join('/');
}

// Replace "example" with whatever you want the asset to be named
export default {
  input: 'assets/main.js',
  output: {
    // The output file need to contain a hash for M::P::Webpack to find it
    file: outPath('example.[hash].js'),

    // "iife" is for web browsers
    format: 'iife',

    name: 'example',
    sourcemap: true,
  },
  plugins: [
    // https://svelte.dev/ specific plugin config
    svelte({
      dev: !production,
      css: (css) => {
        css.write(outPath('example.[hash].css'));
      }
    }),

    resolve(),
    commonjs(),
    production && terser(),

    html({
      dest,
      filename: 'webpack.' + (production ? 'production' : 'development') + '.html',
      inject: 'head',
      template: '<html><head></head><body></body></html>',
    }),
  ],
  watch: {
    clearScreen: false,
  },
};
