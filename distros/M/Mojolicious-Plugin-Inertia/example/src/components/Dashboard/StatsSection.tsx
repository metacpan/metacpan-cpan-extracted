import { router } from '@inertiajs/react'

type Props = {
  stats?: {
    total_todos: number
    completed_todos: number
    pending_todos: number
  }
  loadingSection: string | null
  setLoadingSection: (section: string | null) => void
}

export default function StatsSection({ stats, loadingSection, setLoadingSection }: Props) {
  const refreshStats = () => {
    setLoadingSection('stats')
    router.reload({
      only: ['stats'],
      onFinish: () => setLoadingSection(null),
    })
  }

  return (
    <div className="mb-8">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-xl font-semibold text-gray-800">
          Todo Statistics
          {loadingSection === 'stats' && <span className="text-sm text-gray-500 ml-2">(Updating...)</span>}
        </h2>
        <button
          onClick={refreshStats}
          disabled={loadingSection !== null}
          className="px-3 py-1 bg-gray-500 text-white rounded hover:bg-gray-600 disabled:opacity-50 transition-colors"
        >
          Refresh Stats Only
        </button>
      </div>
      {stats ? (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="bg-white p-6 rounded-lg border border-gray-200">
            <div className="text-2xl font-bold text-gray-900">{stats.total_todos}</div>
            <div className="text-sm text-gray-600">Total Todos</div>
          </div>
          <div className="bg-green-50 p-6 rounded-lg border border-green-200">
            <div className="text-2xl font-bold text-green-700">{stats.completed_todos}</div>
            <div className="text-sm text-green-600">Completed</div>
          </div>
          <div className="bg-amber-50 p-6 rounded-lg border border-amber-200">
            <div className="text-2xl font-bold text-amber-700">{stats.pending_todos}</div>
            <div className="text-sm text-amber-600">Pending</div>
          </div>
        </div>
      ) : (
        <div className="bg-gray-100 p-8 rounded-lg text-center text-gray-500">
          Stats data not loaded
        </div>
      )}
    </div>
  )
}
